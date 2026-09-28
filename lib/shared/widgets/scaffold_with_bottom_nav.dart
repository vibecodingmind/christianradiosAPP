import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/station_detail/station_detail_sheet.dart';
import '../../shared/utils/responsive.dart';
import 'brand_logo.dart';
import 'mini_player.dart';

class ScaffoldWithBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  static const _labels = [
    'HOME',
    'RADIO',
    'GENRES',
    'PRAYERS',
    'ACCOUNT',
  ];

  static const _fullLabels = [
    'Home',
    'Radio',
    'Genres',
    'Prayers',
    'Account',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStation = ref.watch(currentStationProvider);
    final isDark = AppColors.isDark(context);
    final stylePreset = ref.watch(appStyleProvider);

    final navBg = isDark ? const Color(0xFF0E1524) : const Color(0xFFFFFFFF);
    final navBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE6EAF0);
    final activeColor = isDark ? Colors.white : const Color(0xFF181E36);
    final accentColor = stylePreset.primary;
    final inactiveColor = isDark
        ? const Color(0xFF7E92B2)
        : const Color(0xFF8A94A6);

    void onSelectTab(int index) {
      HapticFeedback.selectionClick();
      if (index == 2) {
        ref.read(selectedCategoryProvider.notifier).state = null;
      }
      navigationShell.goBranch(index);
    }

    // ── Page transition animation ──────────────────────────────────────────
    final animatedBody = TweenAnimationBuilder<double>(
      key: ValueKey<int>(navigationShell.currentIndex),
      tween: Tween<double>(begin: 0.94, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Opacity(
          opacity: ((val - 0.94) / 0.06).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - val) * 70),
            child: child,
          ),
        );
      },
      child: navigationShell,
    );

    // ── Bottom nav items ───────────────────────────────────────────────────
    Widget buildBottomNavItem(int index) {
      final label = _labels[index];
      final isSelected = navigationShell.currentIndex == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelectTab(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: isDark ? 0.18 : 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: _ProBottomNavIcon(
                    index: index,
                    isSelected: isSelected,
                    color: isSelected ? activeColor : inactiveColor,
                    accentColor: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: 0.65,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bottomNav = SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentStation != null) const MiniPlayer(),
          Container(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 8),
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: navBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, buildBottomNavItem),
            ),
          ),
        ],
      ),
    );

    // ── Adaptive: bottom nav on mobile, full side rail on tablet/desktop/TV ─
    if (context.useRailNav) {
      final railWidth = context.railNavWidth;

      return Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        body: Row(
          children: [
            // ── Left Navigation Rail (shows BrandLogo + menu + now playing) ─
            Container(
              width: railWidth,
              decoration: BoxDecoration(
                color: navBg,
                border: Border(
                  right: BorderSide(color: navBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),
                    // ── Brand Logo at the top of the side menu ────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => onSelectTab(0),
                          child: const BrandLogo(height: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: navBorder, height: 1),
                    const SizedBox(height: 8),

                    // ── Nav items ─────────────────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _fullLabels.length,
                        itemBuilder: (context, index) {
                          final isSelected = navigationShell.currentIndex == index;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => onSelectTab(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accentColor.withValues(alpha: isDark ? 0.18 : 0.10)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      _ProBottomNavIcon(
                                        index: index,
                                        isSelected: isSelected,
                                        color: isSelected ? activeColor : inactiveColor,
                                        accentColor: accentColor,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _fullLabels[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected ? activeColor : inactiveColor,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Now Playing card in side rail ─────────────────────
                    if (currentStation != null) ...[
                      Divider(color: navBorder, height: 1),
                      _RailNowPlayingCard(
                        station: currentStation,
                        accentColor: accentColor,
                        isDark: isDark,
                        activeColor: activeColor,
                      ),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Main content area + bottom MiniPlayer bar on big screens ──
            Expanded(
              child: Column(
                children: [
                  Expanded(child: animatedBody),
                  if (currentStation != null) const MiniPlayer(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: standard bottom nav ────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: animatedBody,
      bottomNavigationBar: bottomNav,
    );
  }

}

// ── Rail Now Playing Card ──────────────────────────────────────────────────────

/// Full now-playing card shown at the bottom of the expanded (desktop) rail.
class _RailNowPlayingCard extends ConsumerWidget {
  final dynamic station; // Station
  final Color accentColor;
  final bool isDark;
  final Color activeColor;

  const _RailNowPlayingCard({
    required this.station,
    required this.accentColor,
    required this.isDark,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final handler = ref.read(audioHandlerProvider);

    return GestureDetector(
      onTap: () => StationDetailSheet.show(context, station),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Station artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: station.logoUrl as String,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.radio_rounded, color: accentColor, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name + genre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    station.name as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Animated equalizer bars
                      _MiniEqualizerBars(color: accentColor, playing: isPlaying),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isPlaying ? 'Live' : 'Paused',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Play/Pause button
            GestureDetector(
              onTap: () async {
                if (isPlaying) {
                  await handler.pause();
                } else {
                  await handler.play();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated equalizer bars (3 bars, pulsing when playing) ────────────────────

class _MiniEqualizerBars extends StatefulWidget {
  final Color color;
  final bool playing;
  const _MiniEqualizerBars({required this.color, required this.playing});

  @override
  State<_MiniEqualizerBars> createState() => _MiniEqualizerBarsState();
}

class _MiniEqualizerBarsState extends State<_MiniEqualizerBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 120),
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 3, end: 12).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(_MiniEqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) {
      for (final c in _controllers) { c.repeat(reverse: true); }
    } else if (!widget.playing && old.playing) {
      for (final c in _controllers) { c.stop(); }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              final h = widget.playing ? _animations[i].value : 4.0;
              return Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}


/// Bespoke, high-precision vector icons with duotone active fills & crisp strokes
class _ProBottomNavIcon extends StatelessWidget {
  final int index;
  final bool isSelected;
  final Color color;
  final Color accentColor;
  final double size;

  const _ProBottomNavIcon({
    required this.index,
    required this.isSelected,
    required this.color,
    required this.accentColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProBottomNavIconPainter(
          index: index,
          isSelected: isSelected,
          color: color,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _ProBottomNavIconPainter extends CustomPainter {
  final int index;
  final bool isSelected;
  final Color color;
  final Color accentColor;

  _ProBottomNavIconPainter({
    required this.index,
    required this.isSelected,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final duotoneFill = Paint()
      ..color = isSelected
          ? accentColor.withValues(alpha: 0.24)
          : color.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final accentStroke = Paint()
      ..color = isSelected ? accentColor : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (index) {
      case 0:
        _paintHomeIcon(canvas, w, h, strokePaint, duotoneFill, accentStroke);
        break;
      case 1:
        _paintRadioPinIcon(canvas, w, h, strokePaint, duotoneFill, accentStroke);
        break;
      case 2:
        _paintGenresBentoIcon(canvas, w, h, strokePaint, duotoneFill, accentStroke);
        break;
      case 3:
        _paintPrayersSanctuaryIcon(canvas, w, h, strokePaint, duotoneFill, accentStroke);
        break;
      case 4:
        _paintAccountBadgeIcon(canvas, w, h, strokePaint, duotoneFill, accentStroke);
        break;
    }
  }

  /// 0. HOME: Architectural house with arched sanctuary door & rooftop broadcast wave
  void _paintHomeIcon(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint fill,
    Paint accent,
  ) {
    final bodyPath = Path()
      ..moveTo(w * 0.16, h * 0.46)
      ..lineTo(w * 0.50, h * 0.16)
      ..lineTo(w * 0.84, h * 0.46)
      ..lineTo(w * 0.84, h * 0.84)
      ..quadraticBezierTo(w * 0.84, h * 0.88, w * 0.78, h * 0.88)
      ..lineTo(w * 0.22, h * 0.88)
      ..quadraticBezierTo(w * 0.16, h * 0.88, w * 0.16, h * 0.84)
      ..close();

    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, stroke);

    // Arched doorway
    final doorPath = Path()
      ..moveTo(w * 0.40, h * 0.88)
      ..lineTo(w * 0.40, h * 0.63)
      ..arcToPoint(
        Offset(w * 0.60, h * 0.63),
        radius: Radius.circular(w * 0.10),
        clockwise: true,
      )
      ..lineTo(w * 0.60, h * 0.88);
    canvas.drawPath(doorPath, accent);
  }

  /// 1. RADIO: TuneIn-inspired Teardrop Broadcast Signal Pin with Acoustic Waves
  void _paintRadioPinIcon(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint fill,
    Paint accent,
  ) {
    final pinPath = Path()
      ..moveTo(w * 0.50, h * 0.90)
      ..cubicTo(w * 0.24, h * 0.68, w * 0.15, h * 0.52, w * 0.15, h * 0.39)
      ..arcToPoint(
        Offset(w * 0.85, h * 0.39),
        radius: Radius.circular(w * 0.35),
        clockwise: true,
      )
      ..cubicTo(w * 0.85, h * 0.52, w * 0.76, h * 0.68, w * 0.50, h * 0.90)
      ..close();

    canvas.drawPath(pinPath, fill);
    canvas.drawPath(pinPath, stroke);

    // Inner acoustic equalizer bars inside the broadcast pin
    final centerY = h * 0.40;
    canvas.drawLine(
      Offset(w * 0.37, centerY - h * 0.06),
      Offset(w * 0.37, centerY + h * 0.06),
      accent,
    );
    canvas.drawLine(
      Offset(w * 0.50, centerY - h * 0.12),
      Offset(w * 0.50, centerY + h * 0.12),
      accent,
    );
    canvas.drawLine(
      Offset(w * 0.63, centerY - h * 0.06),
      Offset(w * 0.63, centerY + h * 0.06),
      accent,
    );
  }

  /// 2. GENRES: Curated 4-tile Bento Grid with Rotated Diamond Music Accent Tile
  void _paintGenresBentoIcon(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint fill,
    Paint accent,
  ) {
    final r = Radius.circular(w * 0.09);
    final tl = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.14, w * 0.31, h * 0.31),
      r,
    );
    final bl = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.55, w * 0.31, h * 0.31),
      r,
    );
    final br = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.55, h * 0.55, w * 0.31, h * 0.31),
      r,
    );

    canvas.drawRRect(tl, fill);
    canvas.drawRRect(bl, fill);
    canvas.drawRRect(br, fill);

    canvas.drawRRect(tl, stroke);
    canvas.drawRRect(bl, stroke);
    canvas.drawRRect(br, stroke);

    // Top-right rotated diamond accent tile
    canvas.save();
    canvas.translate(w * 0.705, h * 0.295);
    canvas.rotate(math.pi / 4);
    final trDiamond = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.25, height: h * 0.25),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(trDiamond, fill);
    canvas.drawRRect(trDiamond, accent);
    canvas.restore();
  }

  /// 3. PRAYERS: Sanctuary Halo Shield with Radiant Cross & Open Hands Curve
  void _paintPrayersSanctuaryIcon(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint fill,
    Paint accent,
  ) {
    // Soft Halo Circle
    final haloRect = Rect.fromCircle(center: Offset(w * 0.50, h * 0.44), radius: w * 0.32);
    canvas.drawOval(haloRect, fill);

    // Cupped fellowship hands / cradle arc along the bottom
    final cradle = Path()
      ..moveTo(w * 0.15, h * 0.54)
      ..quadraticBezierTo(w * 0.22, h * 0.86, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.78, h * 0.86, w * 0.85, h * 0.54);
    canvas.drawPath(cradle, stroke);

    // Radiant Christian Cross rising from the center
    canvas.drawLine(
      Offset(w * 0.50, h * 0.15),
      Offset(w * 0.50, h * 0.67),
      accent,
    );
    canvas.drawLine(
      Offset(w * 0.33, h * 0.34),
      Offset(w * 0.67, h * 0.34),
      accent,
    );
  }

  /// 4. ACCOUNT: Listener Portrait Badge with Outer Ring
  void _paintAccountBadgeIcon(
    Canvas canvas,
    double w,
    double h,
    Paint stroke,
    Paint fill,
    Paint accent,
  ) {
    final center = Offset(w * 0.50, h * 0.50);
    final outerRadius = w * 0.38;

    canvas.drawCircle(center, outerRadius, fill);
    canvas.drawCircle(center, outerRadius, stroke);

    // Head circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.39), w * 0.125, accent);

    // Shoulders arc
    final shoulders = Path()
      ..moveTo(w * 0.27, h * 0.76)
      ..quadraticBezierTo(w * 0.50, h * 0.57, w * 0.73, h * 0.76);
    canvas.drawPath(shoulders, accent);
  }

  @override
  bool shouldRepaint(covariant _ProBottomNavIconPainter oldDelegate) {
    return oldDelegate.index != index ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor;
  }
}
