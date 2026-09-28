// SPDX-License-Identifier: AGPL-3.0-or-later

/// Routine glyphs and legacy emoji mapping ported from openGym glyphs.js.
library;

import '../ui_kit/icons/app_icon_data.g.dart';

// Ported from ../openGym/frontend/src/lib/glyphs.js:DEFAULT_GLYPH
const String kDefaultGlyph = 'figureStrength';

// Ported from ../openGym/frontend/src/lib/glyphs.js:GLYPH_GROUPS
final class GlyphGroup {
  const GlyphGroup({required this.key, required this.items});
  final String key;
  final List<String> items;
}

const List<GlyphGroup> kGlyphGroups = <GlyphGroup>[
  GlyphGroup(
    key: 'Strength',
    items: <String>['figureStrength', 'arm', 'abs', 'legs', 'pullup'],
  ),
  GlyphGroup(
    key: 'Equipment',
    items: <String>['dumbbell', 'barbell', 'kettlebell', 'plate', 'machine'],
  ),
  GlyphGroup(
    key: 'Cardio',
    items: <String>['figureRun', 'bike', 'swim', 'boxing', 'timer'],
  ),
  GlyphGroup(
    key: 'Recovery',
    items: <String>['stretch', 'moon', 'heart', 'flame', 'bolt'],
  ),
];

// Ported from ../openGym/frontend/src/lib/glyphs.js:GLYPHS
final List<String> kGlyphs =
    kGlyphGroups.expand((GlyphGroup g) => g.items).toList();

// Ported from ../openGym/frontend/src/lib/glyphs.js:LEGACY
const Map<String, String> _kLegacy = <String, String>{
  '💪': 'arm',
  '🦾': 'arm',
  '🫸': 'figureStrength',
  '🫷': 'pullup',
  '🏋️': 'dumbbell',
  '🏋': 'dumbbell',
  '🏋️‍♀️': 'dumbbell',
  '🦵': 'legs',
  '🍑': 'legs',
  '🔥': 'flame',
  '⚡': 'bolt',
  '💥': 'bolt',
  '🧨': 'bolt',
  '😤': 'flame',
  '🏃': 'figureRun',
  '🏃‍♀️': 'figureRun',
  '🚴': 'bike',
  '🏊': 'swim',
  '🤸': 'stretch',
  '🧘': 'stretch',
  '🧘‍♀️': 'stretch',
  '🥊': 'boxing',
  '🧗': 'pullup',
  '⛰️': 'figureRun',
  '🏔️': 'figureRun',
  '🚀': 'bolt',
  '🎯': 'target',
  '🏆': 'trophy',
  '🥇': 'medal',
  '⭐': 'star',
  '🌟': 'star',
  '👑': 'crown',
  '🛡️': 'shield',
  '⚔️': 'shield',
  '❤️‍🔥': 'heart',
  '🦍': 'kettlebell',
  '🐂': 'barbell',
  '🐻': 'kettlebell',
  '🦁': 'boxing',
  '🐺': 'figureRun',
  '🦈': 'swim',
  '🤖': 'machine',
};

// Ported from ../openGym/frontend/src/lib/glyphs.js:glyphOf
String glyphOf(Object? v) {
  if (v == null || v is! String || v.isEmpty) return kDefaultGlyph;
  if (kIconNames.contains(v)) return v;
  if (_kLegacy.containsKey(v)) return _kLegacy[v]!;

  // Strip variation selectors / ZWJ sequences and retry the base emoji.
  final Runes runes = v.runes;
  final List<int> filtered =
      runes.where((int r) => r != 0xFE0F && r != 0x200D).toList();
  if (filtered.isNotEmpty) {
    final String base = String.fromCharCode(filtered.first);
    if (_kLegacy.containsKey(base)) return _kLegacy[base]!;
  }
  return kDefaultGlyph;
}
