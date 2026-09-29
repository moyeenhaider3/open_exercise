// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/i18n/t.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/rows.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import 'edit_card_sheet.dart';

/// Gym cards check-in screen with QR code display.
///
/// Ports `../openGym/frontend/src/views/CheckIn.jsx`.
/// Note: Camera scanning and photo import are deferred to Phase 8 per D-03 / IMP-03.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late PageController _controller;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    final CheckInState state = context.read<CheckInBloc>().state;
    final List<GymCard> cards =
        state is CheckInReady ? state.cards : const <GymCard>[];
    final String? lastId =
        state is CheckInReady ? state.lastGymCardId : null;

    int initialIndex = 0;
    if (lastId != null) {
      final int idx = cards.indexWhere((GymCard c) => c.id == lastId);
      if (idx >= 0) initialIndex = idx;
    }
    _activeIndex = initialIndex;
    _controller = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, CheckInState state) {
    if (state is! CheckInReady) return;
    final int targetIndex;
    if (state.lastGymCardId != null) {
      final int idx =
          state.cards.indexWhere((GymCard c) => c.id == state.lastGymCardId);
      targetIndex = idx >= 0 ? idx : 0;
    } else {
      targetIndex = 0;
    }

    if (_activeIndex >= state.cards.length && state.cards.isNotEmpty) {
      final int clamped = state.cards.length - 1;
      setState(() => _activeIndex = clamped);
      if (_controller.hasClients) {
        _controller.jumpToPage(clamped);
      }
    } else if (targetIndex != _activeIndex && _controller.hasClients) {
      setState(() => _activeIndex = targetIndex);
      _controller.jumpToPage(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return BlocConsumer<CheckInBloc, CheckInState>(
      listener: _onStateChanged,
      builder: (BuildContext context, CheckInState state) {
        final List<GymCard> cards =
            state is CheckInReady ? state.cards : const <GymCard>[];

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4.0, 12.0, 16.0, 0.0),
                  child: Row(
                    children: <Widget>[
                      AppIconButton(
                        'chevronLeft',
                        tooltip: t('Home'),
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                    ],
                  ),
                ),
                ScreenHeader(
                  title: t('Check in'),
                  subtitle: cards.isNotEmpty
                      ? t('Show this at the gym')
                      : t('Add your gym card'),
                ),
                if (cards.isNotEmpty) ...<Widget>[
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: cards.length,
                      onPageChanged: (int idx) {
                        setState(() => _activeIndex = idx);
                        if (idx >= 0 && idx < cards.length) {
                          final String? cardId = cards[idx].id;
                          if (cardId != null) {
                            context
                                .read<CheckInBloc>()
                                .add(CheckInActiveCardChanged(cardId));
                          }
                        }
                      },
                      itemBuilder: (BuildContext context, int i) {
                        final GymCard card = cards[i];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  AppIconButton(
                                    'pencil',
                                    tooltip: t('Edit'),
                                    onPressed: () =>
                                        showEditCardSheet(context, card),
                                  ),
                                  Expanded(
                                    child: Text(
                                      card.label ?? t('Gym card'),
                                      style: const TextStyle(
                                        fontSize: 19.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AppIconButton(
                                    'trash',
                                    tooltip: t('Remove'),
                                    color: palette.red,
                                    onPressed: () async {
                                      final bool confirmed =
                                          await showConfirmSheet(
                                        context,
                                        title: t('Remove this card?'),
                                        message: card.label ?? t('Gym card'),
                                        confirmText: t('Remove'),
                                        danger: true,
                                      );
                                      if (confirmed && context.mounted) {
                                        context.read<CheckInBloc>().add(
                                              CheckInCardRemoved(
                                                  card.id ?? ''),
                                            );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: QrImageView(
                                  data: card.value ?? '',
                                  size: 230.0,
                                  errorStateBuilder:
                                      (BuildContext _, Object? err) =>
                                          const SizedBox(
                                    width: 230.0,
                                    height: 230.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                card.value ?? '',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: palette.muted,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                              const SizedBox(height: 16.0),
                              if (cards.length > 1)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Opacity(
                                      opacity: i == 0 ? 0.3 : 1.0,
                                      child: AppIconButton(
                                        'chevronLeft',
                                        tooltip: t('Move left'),
                                        onPressed: i > 0
                                            ? () => context
                                                .read<CheckInBloc>()
                                                .add(CheckInCardMoved(i, i - 1))
                                            : null,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Text(
                                        '${i + 1} / ${cards.length}',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          color: palette.muted,
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: i == cards.length - 1 ? 0.3 : 1.0,
                                      child: AppIconButton(
                                        'chevronRight',
                                        tooltip: t('Move right'),
                                        onPressed: i < cards.length - 1
                                            ? () => context
                                                .read<CheckInBloc>()
                                                .add(CheckInCardMoved(i, i + 1))
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(cards.length, (int i) {
                        final bool active = i == _activeIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: 7.0,
                          height: 7.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? palette.acc : palette.surface3,
                          ),
                          transform: active
                              ? Matrix4.diagonal3Values(1.15, 1.15, 1.0)
                              : null,
                          transformAlignment: Alignment.center,
                        );
                      }),
                    ),
                  ),
                ] else ...<Widget>[
                  const Spacer(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
