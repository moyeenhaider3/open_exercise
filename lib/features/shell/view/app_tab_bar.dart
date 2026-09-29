// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/t.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/icons/app_icon.dart';

/// Bottom navigation bar ported from openGym `../openGym/frontend/src/components/TabBar.jsx`.
///
/// Features 5 tabs: Home, Plan, Start (raised centre disc), Stats, and Exercises.
/// Start button state (Start, Resume, or Workout) and active indicator follow [GymState.active].
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.location,
  });

  final String location;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static String _currentTab(String location) {
    final List<String> segments =
        location.split('/').where((String s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.first : 'home';
  }

  static bool _isTabActive(String cur, String tabKey) {
    if (cur == tabKey) return true;
    if (cur == 'history' && tabKey == 'stats') return true;
    if (cur == 'settings' && tabKey == 'home') return true;
    if (cur == 'muscles' && tabKey == 'library') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final String cur = _currentTab(widget.location);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: palette.sep,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 60.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildTab(
              context: context,
              palette: palette,
              iconName: 'house',
              label: t('Home'),
              route: AppRoutes.home,
              isActive: _isTabActive(cur, 'home'),
            ),
            _buildTab(
              context: context,
              palette: palette,
              iconName: 'calendar',
              label: t('Plan'),
              route: AppRoutes.plan,
              isActive: _isTabActive(cur, 'plan'),
            ),
            _buildCenterStart(
              context: context,
              palette: palette,
              cur: cur,
            ),
            _buildTab(
              context: context,
              palette: palette,
              iconName: 'chart',
              label: t('Stats'),
              route: AppRoutes.stats,
              isActive: _isTabActive(cur, 'stats'),
            ),
            _buildTab(
              context: context,
              palette: palette,
              iconName: 'list',
              label: t('Exercises'),
              route: AppRoutes.library,
              isActive: _isTabActive(cur, 'library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required AppPalette palette,
    required String iconName,
    required String label,
    required String route,
    required bool isActive,
  }) {
    final Color color = isActive ? palette.acc : palette.muted;

    return Expanded(
      child: InkResponse(
        onTap: () => context.go(route),
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppIcon(
              iconName,
              size: 24.0,
              color: color,
              strokeWidth: isActive ? 2.0 : 1.65,
            ),
            const SizedBox(height: 3.0),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterStart({
    required BuildContext context,
    required AppPalette palette,
    required String cur,
  }) {
    return Expanded(
      child: BlocSelector<GymStateCubit, GymState, bool>(
        selector: (GymState state) => state.active != null,
        builder: (BuildContext context, bool hasActive) {
          final String label = hasActive
              ? (cur == 'workout' ? t('Workout') : t('Resume'))
              : t('Start');
          final String iconName = hasActive
              ? (cur == 'workout' ? 'dumbbell' : 'play')
              : 'dumbbell';
          final Color discBg = hasActive ? palette.orange : palette.acc;
          final Color discFg = hasActive ? Colors.black : palette.onAcc;
          final Color labelColor = hasActive ? palette.orange : palette.acc;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Plan 03-16 replaces this handler with direct start of today's routines
            // (TabBar.startWorkout) once WorkoutBloc's start flow exists.
            onTap: () => context.go(AppRoutes.workout),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const SizedBox(height: 38.0),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                  ],
                ),
                Positioned(
                  top: -16.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      if (hasActive)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (BuildContext context, Widget? child) {
                            return Container(
                              width: 52.0 * _pulseAnimation.value,
                              height: 52.0 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.orange.withValues(
                                    alpha: (1.0 - (_pulseController.value)).clamp(0.0, 0.7),
                                  ),
                                  width: 2.0,
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: 52.0,
                        height: 52.0,
                        decoration: BoxDecoration(
                          color: discBg,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: discBg.withValues(alpha: 0.45),
                              blurRadius: 14.0,
                              offset: const Offset(0.0, 4.0),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AppIcon(
                            iconName,
                            size: 26.0,
                            color: discFg,
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
