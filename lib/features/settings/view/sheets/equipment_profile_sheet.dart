// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/state_parts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';

/// Shows the equipment profile create/edit sheet.
///
/// Ports openGym `sheets.jsx`:1076-1116 EquipmentProfileSheet.
Future<void> showEquipmentProfileSheet(
  BuildContext context,
  EquipProfile? profile,
) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _EquipmentProfileSheet(profile: profile),
  );
}

class _EquipmentProfileSheet extends StatefulWidget {
  const _EquipmentProfileSheet({this.profile});

  final EquipProfile? profile;

  @override
  State<_EquipmentProfileSheet> createState() => _EquipmentProfileSheetState();
}

class _EquipmentProfileSheetState extends State<_EquipmentProfileSheet> {
  late final TextEditingController _nameController;
  late final Set<String> _checked;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _checked = Set<String>.from(widget.profile?.equipment ?? const <String>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    context.read<SettingsBloc>().add(
          SettingsEquipProfileSaved(
            id: widget.profile?.id,
            name: name,
            equipment: _checked.toList(),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<String> allEquipment =
        context.read<ExerciseCatalogue>().allEquipment;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.profile != null
              ? t('Edit profile')
              : t('New equipment profile'),
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          t('Name it after where you train — e.g. "Home" or "Gym" — then check what you have there.'),
          style: TextStyle(
            fontSize: 14.0,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 14.0),
        TextField(
          controller: _nameController,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: t('Profile name'),
            filled: true,
            fillColor: palette.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: allEquipment.map((String k) {
            final bool isSelected = _checked.contains(k);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _checked.remove(k);
                  } else {
                    _checked.add(k);
                  }
                });
              },
              borderRadius: BorderRadius.circular(99.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? palette.acc : palette.surface2,
                  borderRadius: BorderRadius.circular(99.0),
                ),
                child: Text(
                  t(k),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? palette.onAcc
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10.0),
        Text(
          t('Body-weight exercises are always available, in every profile.'),
          style: TextStyle(
            fontSize: 13.0,
            color: palette.dim,
          ),
        ),
        const SizedBox(height: 14.0),
        AppButton(
          variant: AppButtonVariant.primary,
          label: Text(t('Save')),
          onPressed: _save,
        ),
      ],
    );
  }
}
