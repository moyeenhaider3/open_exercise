// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';

/// Opens the routine icon / glyph picker modal sheet.
/// Ported from ../openGym/frontend/src/sheets.jsx:1427-1453 glyphPicker.
Future<String?> showGlyphPickerSheet(
  BuildContext context, {
  String? current,
}) {
  return showAppSheet<String>(
    context,
    (BuildContext ctx) => _GlyphPickerContent(current: current),
  );
}

class _GlyphPickerContent extends StatelessWidget {
  const _GlyphPickerContent({this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      height: 420.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 12.0),
            child: Text(
              t('Choose icon'),
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: <Widget>[
                for (final GlyphGroup group in kGlyphGroups) ...<Widget>[
                  SliverToBoxAdapter(
                    child: SectionHeader(t(group.key)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext ctx, int index) {
                          final String glyph = group.items[index];
                          final bool isSelected = glyph == current;

                          return InkWell(
                            onTap: () => Navigator.of(ctx).pop(glyph),
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? palette.acc : palette.surface2,
                                borderRadius: BorderRadius.circular(12.0),
                                border: isSelected
                                    ? Border.all(color: palette.acc, width: 2.0)
                                    : null,
                              ),
                              child: Center(
                                child: AppIcon(
                                  glyph,
                                  size: 26.0,
                                  color: isSelected ? palette.onAcc : palette.muted,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: group.items.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12.0),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
