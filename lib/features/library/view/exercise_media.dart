// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/i18n/t.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_event.dart';

/// Interactive exercise animation media player.
/// Ported from ../openGym/frontend/src/components/Media.jsx.
///
/// CACHING:
/// Relies on Flutter's built-in [PaintingBinding.instance.imageCache] (in-memory LRU).
/// Images and GIFs decoded from openGym's pinned CDN survive across rebuilds and repeat
/// screen views in memory without introducing third-party disk cache dependencies (UI-02).
class ExerciseMedia extends StatefulWidget {
  const ExerciseMedia({
    super.key,
    required this.ex,
    this.compact = false,
    this.minimizable = false,
  });

  final ExerciseDef ex;
  final bool compact;
  final bool minimizable;

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia> {
  bool _playing = true;
  String? _failed; // null | 'gif' | 'all'

  void _handleTap() {
    setState(() {
      if (_failed != null) {
        _failed = null;
        _playing = true;
      } else {
        _playing = !_playing;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ex.gif == null && widget.ex.img == null) {
      return const SizedBox.shrink();
    }

    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final String? gifSize = context.select<GymStateCubit, String?>(
      (GymStateCubit c) => c.state.gifSize,
    );

    if (widget.minimizable && gifSize == 'off') {
      return const SizedBox.shrink();
    }

    final bool isMini = widget.minimizable && gifSize == 'mini';
    final bool showGif = _playing && _failed == null;

    final String? gifUrl = catalogue.gifSrc(widget.ex);
    final String? imgUrl = catalogue.imgSrc(widget.ex);
    final String? targetUrl = showGif ? (gifUrl ?? imgUrl) : imgUrl;

    if (targetUrl == null || _failed == 'all') {
      return Semantics(
        label: catalogue.exerciseNameFor(widget.ex),
        child: Container(
          height: isMini ? 80.0 : (widget.compact ? 160.0 : 220.0),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Center(
            child: AppIcon('dumbbell', size: 36.0, color: palette.muted),
          ),
        ),
      );
    }

    final double height = isMini ? 80.0 : (widget.compact ? 160.0 : 220.0);

    return Semantics(
      label: catalogue.exerciseNameFor(widget.ex),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: _handleTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Container(
                width: double.infinity,
                height: height,
                color: palette.surface2,
                child: Image.network(
                  targetUrl,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _failed = _failed == null ? 'gif' : 'all';
                        });
                      }
                    });
                    return Container(
                      color: palette.surface2,
                      child: Center(
                        child: AppIcon(
                          'dumbbell',
                          size: 32.0,
                          color: palette.muted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Minimize / Expand toggle button
          if (widget.minimizable)
            Positioned(
              top: 8.0,
              right: 8.0,
              child: InkWell(
                onTap: () {
                  context.read<ExercisesBloc>().add(const MediaSizeToggled());
                },
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppIcon(
                        isMini ? 'chevronDown' : 'chevronUp',
                        size: 14.0,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        isMini ? t('Expand') : t('Minimize'),
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tap to pause/play hint (shown only when full size and not failed)
          if (!isMini && _failed == null)
            Positioned(
              bottom: 8.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  _playing ? t('Tap to pause') : t('Tap to play'),
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Static thumbnail image for an exercise item with placeholder fallback.
/// Ported from ../openGym/frontend/src/components/Media.jsx:Thumb.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({
    super.key,
    required this.ex,
    this.size = 40.0,
  });

  final ExerciseDef ex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final String? imgUrl = catalogue.imgSrc(ex);

    if (imgUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: AppIcon('dumbbell', size: size * 0.5, color: palette.muted),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: size,
        height: size,
        color: palette.surface2,
        child: Image.network(
          imgUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).round(),
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return Container(
              color: palette.surface2,
              child: Center(
                child: AppIcon(
                  'dumbbell',
                  size: size * 0.5,
                  color: palette.muted,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
