// SPDX-License-Identifier: AGPL-3.0-or-later

/// Lazy, process-wide geometry cache that parses SVG assets with `xml` and
/// `path_drawing` into cached `Path` objects.
///
/// Mirrors openGym's `components/BodyMap.jsx` lines 14-27 (CACHE/PENDING).
library;

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

enum BodyPartKind { inert, muscle }

/// Individual path element representing an inert or muscle body part.
final class BodyPart {
  const BodyPart({
    required this.slug,
    required this.kind,
    required this.path,
  });

  final String slug;
  final BodyPartKind kind;
  final Path path;
}

/// Geometry for one view (front or back) containing viewBox and parts in paint order.
final class BodyViewGeometry {
  const BodyViewGeometry({
    required this.viewBox,
    required this.parts,
  });

  final Rect viewBox;
  final List<BodyPart> parts;

  Iterable<BodyPart> get muscles => parts.where((BodyPart p) => p.kind == BodyPartKind.muscle);
}

/// Paired front and back geometries for a body type.
final class BodyGeometry {
  const BodyGeometry({
    required this.front,
    required this.back,
  });

  final BodyViewGeometry front;
  final BodyViewGeometry back;
}

/// Process-wide lazy cache for parsed body geometry.
final class BodyGeometryCache {
  BodyGeometryCache._();

  static final BodyGeometryCache instance = BodyGeometryCache._();

  final Map<String, BodyGeometry> _cache = <String, BodyGeometry>{};
  final Map<String, Future<BodyGeometry>> _pending = <String, Future<BodyGeometry>>{};

  /// Normalizes body gender; returns 'female' only when explicit, else 'male'.
  static String normalizeBody(String? body) => body == 'female' ? 'female' : 'male';

  /// Synchronous peek at already-parsed geometry so cached maps do not flash.
  BodyGeometry? peek(String? body) => _cache[normalizeBody(body)];

  /// Loads and parses body geometry once per body type, sharing in-flight futures.
  Future<BodyGeometry> load(AssetBundle bundle, String? body) {
    final String key = normalizeBody(body);
    final BodyGeometry? cached = _cache[key];
    if (cached != null) {
      return Future<BodyGeometry>.value(cached);
    }

    final Future<BodyGeometry>? pending = _pending[key];
    if (pending != null) {
      return pending;
    }

    final Future<BodyGeometry> future = _loadGeometry(bundle, key);
    _pending[key] = future;
    return future;
  }

  Future<BodyGeometry> _loadGeometry(AssetBundle bundle, String key) async {
    try {
      final BodyViewGeometry front = await _loadView(bundle, key, 'front');
      final BodyViewGeometry back = await _loadView(bundle, key, 'back');
      final BodyGeometry geometry = BodyGeometry(front: front, back: back);
      _cache[key] = geometry;
      _pending.remove(key);
      return geometry;
    } catch (_) {
      _pending.remove(key);
      rethrow;
    }
  }

  Future<BodyViewGeometry> _loadView(AssetBundle bundle, String body, String view) async {
    final String assetPath = 'assets/body/$body-$view.svg';
    final String svgText = await bundle.loadString(assetPath);
    final XmlDocument doc = XmlDocument.parse(svgText);

    final String? vbAttr = doc.rootElement.getAttribute('viewBox');
    if (vbAttr == null) {
      throw FormatException('Missing viewBox in $assetPath');
    }

    final List<double> vbParts = vbAttr
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .map(double.parse)
        .toList();

    if (vbParts.length != 4) {
      throw FormatException('Invalid viewBox "$vbAttr" in $assetPath');
    }

    final Rect viewBox = Rect.fromLTWH(vbParts[0], vbParts[1], vbParts[2], vbParts[3]);
    final List<BodyPart> parts = <BodyPart>[];

    for (final XmlElement el in doc.findAllElements('path')) {
      final String? slug = el.getAttribute('data-part');
      final String? kindStr = el.getAttribute('data-kind');
      final String? d = el.getAttribute('d');

      if (slug == null || kindStr == null || d == null) {
        throw FormatException('Malformed path in $assetPath: slug=$slug, kind=$kindStr');
      }

      final BodyPartKind kind;
      if (kindStr == 'inert') {
        kind = BodyPartKind.inert;
      } else if (kindStr == 'muscle') {
        kind = BodyPartKind.muscle;
      } else {
        throw FormatException('Unknown data-kind "$kindStr" in $assetPath');
      }

      final Path path = parseSvgPathData(d);
      parts.add(BodyPart(slug: slug, kind: kind, path: path));
    }

    return BodyViewGeometry(viewBox: viewBox, parts: parts);
  }
}
