// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/i18n/t.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/toast.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';

/// Opens the edit card modal sheet.
///
/// Ports openGym `views/CheckIn.jsx` CardSheet (editing mode).
/// Note: Scanning and image import are deferred to Phase 8 per D-03 / IMP-03.
Future<void> showEditCardSheet(BuildContext context, GymCard card) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _EditCardSheet(card: card),
  );
}

class _EditCardSheet extends StatefulWidget {
  const _EditCardSheet({required this.card});

  final GymCard card;

  @override
  State<_EditCardSheet> createState() => _EditCardSheetState();
}

class _EditCardSheetState extends State<_EditCardSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.card.label ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<CheckInBloc>().add(
      CheckInCardRenamed(widget.card.id ?? '', _ctrl.text),
    );
    Navigator.of(context).pop();
    showToast(context, t('Card updated'));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Edit card'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        Text(
          t('Label'),
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: t('e.g. FitZone downtown'),
            hintStyle: TextStyle(color: palette.dim),
            filled: true,
            fillColor: palette.surface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.all(12.0),
            child: QrImageView(
              data: widget.card.value ?? '',
              size: 150.0,
              errorStateBuilder: (BuildContext _, Object? err) => const SizedBox(
                width: 150.0,
                height: 150.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        AppButton(
          label: Text(t('Save card')),
          variant: AppButtonVariant.primary,
          onPressed: _save,
        ),
      ],
    );
  }
}
