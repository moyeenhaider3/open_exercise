// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

/// openGym's 8 accent colours, ported 1:1 from
/// `../openGym/frontend/src/lib/format.js:94` (`ACCENTS`).
const Map<String, Color> kAccents = <String, Color>{
  'lime': Color(0xFF30D158),
  'sky': Color(0xFF0A84FF),
  'orange': Color(0xFFFF9F0A),
  'violet': Color(0xFFBF5AF2),
  'pink': Color(0xFFFF375F),
  'red': Color(0xFFFF453A),
  'teal': Color(0xFF40C8E0),
  'gold': Color(0xFFFFD60A),
};

/// openGym's default accent key (`useStore.js` DEF, mirrored by
/// `GymState.defaultAccent`).
const String kDefaultAccentKey = 'lime';
