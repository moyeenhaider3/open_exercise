// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Returns delta indicator color matching openGym `sheets.jsx` lines 550-555.
///
/// Ported from ../openGym/frontend/src/sheets.jsx:550-555:
/// ```js
/// export function bwDeltaColor(delta, currentW) {
///   if (!delta) return 'var(--label-2)'
///   if (!S().targetW) return 'var(--label)'
///   const up = S().targetW > currentW
///   return (delta > 0) === up ? 'var(--acc)' : 'var(--red)'
/// }
/// ```
Color bwDeltaColor(BuildContext context, num? delta, num currentW, num? targetW) {
  final AppPalette palette = AppPalette.of(context);
  if (delta == null || delta == 0) {
    return palette.muted;
  }
  if (targetW == null) {
    return Theme.of(context).colorScheme.onSurface;
  }
  final bool up = targetW > currentW;
  return (delta > 0) == up ? palette.acc : palette.red;
}
