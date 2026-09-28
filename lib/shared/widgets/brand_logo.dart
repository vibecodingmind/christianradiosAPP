import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'app_menu_sheet.dart';
import 'brand_logo_bytes.dart';

/// Renders the official ChristianRadios.org web logo (`((christian)) radios.org`),
/// automatically adapting between dark and light backgrounds using embedded
/// high-DPI PNG bytes so it renders instantaneously with zero asset/network errors.
class BrandLogo extends StatelessWidget {
  final double height;
  final bool onDarkSurface;

  const BrandLogo({
    super.key,
    this.height = 34,
    this.onDarkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = onDarkSurface || AppColors.isDark(context);
    final bytes = isDark ? kBrandLogoDarkBytes : kBrandLogoLightBytes;

    return Image.memory(
      bytes,
      height: height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    );
  }
}

/// Top AppBar right actions:
/// - Instant Sun / Moon theme switcher
/// - App Menu button
class AppHeaderActions extends ConsumerWidget {
  const AppHeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final fg = AppColors.appBarFg(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              key: ValueKey<bool>(isDark),
              color: fg,
              size: 22,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.menu_rounded, color: fg, size: 25),
          tooltip: 'App Menu',
          onPressed: () => AppMenuSheet.show(context),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
