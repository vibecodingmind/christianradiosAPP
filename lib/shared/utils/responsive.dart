/// Responsive layout utilities.
/// All decisions are based on available window width — never on device hardware type.
///
/// Breakpoints (inspired by Material You adaptive design):
///   compact   < 600 px   → phone
///   medium    600–1023   → tablet / large phone / foldable
///   expanded  ≥ 1024 px  → desktop / TV / large tablet
library;

import 'package:flutter/material.dart';

// ── Breakpoint constants ───────────────────────────────────────────────────────

const double kCompactBreakpoint = 600.0;
const double kExpandedBreakpoint = 1024.0;

// ── Enum ──────────────────────────────────────────────────────────────────────

enum ScreenClass { compact, medium, expanded }

// ── Extension on BuildContext ─────────────────────────────────────────────────

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenClass get screenClass {
    final w = screenWidth;
    if (w >= kExpandedBreakpoint) return ScreenClass.expanded;
    if (w >= kCompactBreakpoint) return ScreenClass.medium;
    return ScreenClass.compact;
  }

  bool get isCompact => screenClass == ScreenClass.compact;
  bool get isMedium => screenClass == ScreenClass.medium;
  bool get isExpanded => screenClass == ScreenClass.expanded;

  /// True when tablet OR desktop (medium or expanded).
  bool get isLarge => !isCompact;

  // ── Responsive helpers ────────────────────────────────────────────────────

  /// Number of columns for a station card grid.
  int get stationGridColumns {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 3;
      case ScreenClass.medium:
        return 2;
      case ScreenClass.compact:
        return 1;
    }
  }

  /// Number of columns for a category grid.
  int get categoryGridColumns {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 5;
      case ScreenClass.medium:
        return 3;
      case ScreenClass.compact:
        return 2;
    }
  }

  /// Tile size for horizontal station carousels.
  double get carouselTileSize {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 160.0;
      case ScreenClass.medium:
        return 140.0;
      case ScreenClass.compact:
        return 118.0;
    }
  }

  /// Hero banner height.
  double get heroBannerHeight {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 280.0;
      case ScreenClass.medium:
        return 230.0;
      case ScreenClass.compact:
        return 194.0;
    }
  }

  /// Featured collection tile size.
  double get featuredTileSize {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 160.0;
      case ScreenClass.medium:
        return 140.0;
      case ScreenClass.compact:
        return 118.0;
    }
  }

  /// Genre card size.
  double get genreTileSize {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 160.0;
      case ScreenClass.medium:
        return 140.0;
      case ScreenClass.compact:
        return 118.0;
    }
  }

  /// Max content width for large-screen centering.
  double get contentMaxWidth {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 1280.0;
      case ScreenClass.medium:
        return 860.0;
      case ScreenClass.compact:
        return double.infinity;
    }
  }

  /// Horizontal page padding.
  double get pagePadding {
    switch (screenClass) {
      case ScreenClass.expanded:
        return 28.0;
      case ScreenClass.medium:
        return 20.0;
      case ScreenClass.compact:
        return 16.0;
    }
  }

  /// Number of hero banner cards visible at once in the PageView.
  double get heroViewportFraction {
    final w = screenWidth;
    if (w >= 1100) return 0.33; // 3 featured hero cards side-by-side on large tablets/desktop/TV
    if (w >= 600) return 0.48;  // 2 featured hero cards side-by-side on tablets
    return 0.90;
  }

  /// Whether to show left rail navigation instead of bottom nav.
  bool get useRailNav => isLarge;

  /// Width of the left rail navigation.
  double get railNavWidth {
    if (isExpanded) return 240.0;
    if (isMedium) return 208.0; // Full labeled rail with BrandLogo on tablets too
    return 0.0;
  }
}

// ── Centering wrapper for large screens ───────────────────────────────────────

/// Wraps [child] in a centered [ConstrainedBox] capped at [maxWidth].
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1280.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
