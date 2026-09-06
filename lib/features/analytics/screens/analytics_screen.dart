import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/repositories/repository_providers.dart';

/// Phase 6.4 — Route Analytics Dashboard.
///
/// A premium, mobile-first analytics screen showing KPIs, per-route performance,
/// 7-day reliability trends, and AI-powered prediction insights.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({required this.routeId, super.key});
  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAnalytics = ref.watch(allAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium app bar ───────────────────────────────────────────────
          _PremiumSliverAppBar(routeId: routeId),

          // ── KPI cards ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: allAnalytics.when(
                data: (bundles) => _KpiSection(bundles: bundles),
                loading: () => const _KpiSkeleton(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── 7-day trend chart ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: allAnalytics.when(
                data: (bundles) {
                  final bundle = bundles.cast<AnalyticsBundle?>().firstWhere(
                        (b) => b?.routeId == routeId,
                        orElse: () => bundles.first,
                      );
                  if (bundle == null) return const SizedBox.shrink();
                  return _TrendCard(bundle: bundle);
                },
                loading: () => const _CardSkeleton(height: 200),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Route performance list ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Route Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
          allAnalytics.when(
            data: (bundles) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bundle = bundles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RoutePerformanceCard(
                        bundle: bundle,
                        isSelected: bundle.routeId == routeId,
                      ),
                    );
                  },
                  childCount: bundles.length,
                ),
              ),
            ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CardSkeleton(height: 100),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ── AI predictions ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: allAnalytics.when(
                data: (bundles) => _AiPredictionsSection(bundles: bundles),
                loading: () => const _CardSkeleton(height: 200),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Bottom safe area
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}

// ─── Premium app bar ─────────────────────────────────────────────────────────

class _PremiumSliverAppBar extends StatelessWidget {
  const _PremiumSliverAppBar({required this.routeId});
  final String routeId;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: AppSpacing.md, bottom: 16),
        title: Text(
          'Analytics ${routeId.toUpperCase()}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
        ),
      ),
    );
  }
}

// ─── KPI Section ───────────────────────────────────────────────────────────

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.bundles});
  final List<AnalyticsBundle> bundles;

  @override
  Widget build(BuildContext context) {
    // Aggregate across all routes.
    final avgOnTime = bundles.map((b) => b.onTimePercentage).reduce((a, b) => a + b) / bundles.length;
    final avgDelay = bundles.map((b) => b.averageDelayMinutes).reduce((a, b) => a + b) / bundles.length;
    final avgReliability = bundles.map((b) => b.reliabilityScore).reduce((a, b) => a + b) / bundles.length;
    final allPeaks = bundles.map((b) => b.peakPeriod).join(', ');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AnimatedKpiCard(
                label: 'On-Time',
                value: '${avgOnTime.round()}%',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                trend: '+2%',
                trendUp: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AnimatedKpiCard(
                label: 'Avg Delay',
                value: '${avgDelay.round()} min',
                icon: Icons.access_time_rounded,
                color: AppColors.warning,
                trend: '-1 min',
                trendUp: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _AnimatedKpiCard(
                label: 'Reliability',
                value: avgReliability.round().toString(),
                icon: Icons.speed_rounded,
                color: AppColors.primary,
                trend: '+1',
                trendUp: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AnimatedKpiCard(
                label: 'Peak Traffic',
                value: allPeaks.split(',').first,
                icon: Icons.traffic_rounded,
                color: AppColors.accent,
                trend: '',
                trendUp: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedKpiCard extends StatefulWidget {
  const _AnimatedKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendUp,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendUp;

  @override
  State<_AnimatedKpiCard> createState() => _AnimatedKpiCardState();
}

class _AnimatedKpiCardState extends State<_AnimatedKpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const Spacer(),
                if (widget.trend.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.trendUp
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.trendUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 10,
                          color: widget.trendUp ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.trend,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.trendUp ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 7-day trend chart ─────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-Day Reliability Trend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      bundle.routeShortName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${bundle.reliabilityScore.round()} avg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: _TrendChart(
              points: bundle.reliabilityTrend,
              color: Color(bundle.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight custom trend chart — no external chart package.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.color});
  final List<TrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Column(
          children: [
            // Chart area
            Expanded(
              child: CustomPaint(
                size: Size(w, h - 20),
                painter: _TrendChartPainter(points: points, color: color),
              ),
            ),
            // Day labels
            SizedBox(
              height: 20,
              child: Row(
                children: points.map((p) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        p.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.points, required this.color});
  final List<TrendPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minV = points.map((p) => p.value).reduce(math.min);
    final maxV = points.map((p) => p.value).reduce(math.max);
    final range = (maxV - minV).clamp(1.0, 100.0);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final segmentWidth = size.width / (points.length - 1).clamp(1, points.length);

    // Build path
    final linePath = Path();
    final fillPath = Path();
    final offsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = i * segmentWidth + segmentWidth / 2;
      final y = size.height - ((points[i].value - minV) / range) * size.height;
      offsets.add(Offset(x, y));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw gradient fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    for (final offset in offsets) {
      canvas.drawCircle(offset, 4.5, dotBorderPaint);
      canvas.drawCircle(offset, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) =>
      old.points != points;
}

// ─── Route Performance cards ────────────────────────────────────────────────

class _RoutePerformanceCard extends StatelessWidget {
  const _RoutePerformanceCard({
    required this.bundle,
    required this.isSelected,
  });
  final AnalyticsBundle bundle;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final routeColor = Color(bundle.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? routeColor.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: isSelected
            ? Border.all(color: routeColor.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: routeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    bundle.routeShortName,
                    style: TextStyle(
                      color: routeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bundle.origin} → ${bundle.destination}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      bundle.peakPeriod,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bundle.reliabilityScore.round()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: routeColor,
                        ),
                  ),
                  Text(
                    'reliability',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Reliability progress bar
          _ReliabilityBar(
            score: bundle.reliabilityScore,
            color: routeColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                label: '${bundle.onTimePercentage.round()}%',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatChip(
                icon: Icons.access_time_rounded,
                label: '+${bundle.averageDelayMinutes.round()} min',
                color: AppColors.warning,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? routeColor.withValues(alpha: 0.12)
                      : AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSelected ? 'Tracking' : 'View',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? routeColor : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReliabilityBar extends StatelessWidget {
  const _ReliabilityBar({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reliability',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
            ),
            Text(
              '${score.round()}/100',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Predictions ─────────────────────────────────────────────────────────

class _AiPredictionsSection extends StatelessWidget {
  const _AiPredictionsSection({required this.bundles});
  final List<AnalyticsBundle> bundles;

  /// Deterministic insights per route (not from an API — Phase 6.4 mock).
  List<AnalyticsInsight> get _insights {
    return [
      AnalyticsInsight(
        routeId: 'r1',
        routeName: 'R1',
        title: 'High Delay Probability',
        message:
            'Expect delays near Campal after 5 PM due to peak-hour congestion.',
        severity: InsightSeverity.warning,
        confidence: 0.82,
      ),
      AnalyticsInsight(
        routeId: 'r1',
        routeName: 'R1',
        title: 'Usually On Time',
        message:
            'This route typically reaches Miramar within 6–8 min of the estimate.',
        severity: InsightSeverity.info,
        confidence: 0.91,
      ),
      AnalyticsInsight(
        routeId: 'r2',
        routeName: 'R2',
        title: 'Moderate Crowding',
        message: 'Expect moderate crowding during the 8–10 AM school commute.',
        severity: InsightSeverity.warning,
        confidence: 0.74,
      ),
      AnalyticsInsight(
        routeId: 'r3',
        routeName: 'R3',
        title: 'Airport Traffic Alert',
        message:
            'Traffic likely near Chicalim during flight departure windows.',
        severity: InsightSeverity.warning,
        confidence: 0.78,
      ),
      AnalyticsInsight(
        routeId: 'r3',
        routeName: 'R3',
        title: 'Reliability Improving',
        message: 'This route\'s reliability has improved 4 points over the week.',
        severity: InsightSeverity.info,
        confidence: 0.89,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final insights = _insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'AI Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BETA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...insights.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InsightCard(insight: i),
            )),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final AnalyticsInsight insight;

  (IconData, Color) get _theme {
    switch (insight.severity) {
      case InsightSeverity.critical:
        return (Icons.error_outline_rounded, AppColors.danger);
      case InsightSeverity.warning:
        return (Icons.warning_amber_rounded, AppColors.warning);
      case InsightSeverity.info:
        return (Icons.lightbulb_outline_rounded, AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _theme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(insight.confidence * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(insight.routeId == 'r1'
                            ? 0xFF00897B
                            : insight.routeId == 'r2'
                                ? 0xFFE65100
                                : 0xFF1565C0)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    insight.routeName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(insight.routeId == 'r1'
                          ? 0xFF00897B
                          : insight.routeId == 'r2'
                              ? 0xFFE65100
                              : 0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton loaders ───────────────────────────────────────────────────────

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: _ShimmerBox(),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)))),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)))),
          ],
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0x0A000000),
                Color(0x15000000),
                Color(0x0A000000),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
