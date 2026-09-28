import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// An animated audio wave visualizer that animates vertical bars
/// to indicate live audio playback. Supports both a mini badge mode (4-5 bars)
/// and a full spectrum visualizer mode (24+ bars).
class AudioWaveIndicator extends StatefulWidget {
  final bool isPlaying;
  final bool isMini;
  final int barCount;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final LinearGradient? gradient;

  const AudioWaveIndicator({
    super.key,
    required this.isPlaying,
    this.isMini = false,
    this.barCount = 4,
    this.height = 18,
    this.activeColor,
    this.inactiveColor,
    this.gradient,
  });

  /// Factory for a full station detail spectrum visualizer banner
  const AudioWaveIndicator.visualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 28,
    this.height = 42,
    this.activeColor,
    this.inactiveColor,
    this.gradient,
  }) : isMini = false;

  /// Factory for compact cards and mini player
  const AudioWaveIndicator.mini({
    super.key,
    required this.isPlaying,
    this.barCount = 4,
    this.height = 14,
    this.activeColor,
    this.inactiveColor,
    this.gradient,
  }) : isMini = true;

  @override
  State<AudioWaveIndicator> createState() => _AudioWaveIndicatorState();
}

class _AudioWaveIndicatorState extends State<AudioWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBarCount = widget.isMini ? widget.barCount.clamp(3, 6) : widget.barCount;
    final barWidth = widget.isMini ? 2.5 : 3.5;
    final spacing = widget.isMini ? 2.0 : 3.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(effectiveBarCount, (index) {
              // Calculate animated height for each bar using harmonic phase offsets
              final phase = (index / effectiveBarCount) * 2 * math.pi;
              final t = _controller.value * 2 * math.pi;

              // Compound waves to produce realistic, organic sound spectrum motion
              final sine1 = math.sin(t * 1.5 + phase);
              final sine2 = math.cos(t * 2.3 + phase * 1.8);
              final combined = ((sine1 + sine2 + 2.0) / 4.0).clamp(0.0, 1.0);

              final minHeightFraction = widget.isMini ? 0.25 : 0.15;
              final heightFactor = widget.isPlaying
                  ? minHeightFraction + (1.0 - minHeightFraction) * combined
                  : minHeightFraction;

              final barHeight = (widget.height * heightFactor).clamp(3.0, widget.height);

              // Colors & Gradients
              final defaultActiveColor = index % 2 == 0 ? AppColors.primary : AppColors.accent;
              final defaultInactive = AppColors.onSurfaceMuted.withValues(alpha: 0.35);

              Widget barWidget = Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(barWidth / 2),
                  color: widget.gradient == null
                      ? (widget.isPlaying
                          ? (widget.activeColor ?? defaultActiveColor)
                          : (widget.inactiveColor ?? defaultInactive))
                      : null,
                  gradient: widget.isPlaying
                      ? (widget.gradient ??
                          const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ))
                      : null,
                ),
              );

              if (index < effectiveBarCount - 1) {
                return Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: barWidget,
                );
              }
              return barWidget;
            }),
          ),
        );
      },
    );
  }
}

/// Centered animated audio-wave preloader used across screens while fetching stations/categories/prayers.
class AudioWavePreloader extends StatelessWidget {
  final String? label;
  final double height;
  final int barCount;
  final Color? color;

  const AudioWavePreloader({
    super.key,
    this.label,
    this.height = 32,
    this.barCount = 7,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.pinkAccent;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AudioWaveIndicator(
            isPlaying: true,
            barCount: barCount,
            height: height,
            activeColor: activeColor,
            gradient: LinearGradient(
              colors: [AppColors.royalBlue, activeColor],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

