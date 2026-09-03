import 'package:flutter/material.dart';

enum AppBreakpoint { compact, medium, expanded }

class Responsive {
  static AppBreakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return AppBreakpoint.expanded;
    if (width >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }

  static bool useSideNav(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 960;
    if (width >= 900) return 760;
    if (width >= 600) return 560;
    return width;
  }

  static double authMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 480;
    if (width >= 600) return 440;
    return width - 24;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
    if (width >= 600) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.all(16);
  }

  static int gridColumns(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
  }) {
    return switch (of(context)) {
      AppBreakpoint.compact => compact,
      AppBreakpoint.medium => medium,
      AppBreakpoint.expanded => expanded,
    };
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 1,
    this.mediumColumns = 2,
    this.expandedColumns = 3,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(
      context,
      compact: compactColumns,
      medium: mediumColumns,
      expanded: expandedColumns,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth.clamp(0, constraints.maxWidth), child: child),
          ],
        );
      },
    );
  }
}
