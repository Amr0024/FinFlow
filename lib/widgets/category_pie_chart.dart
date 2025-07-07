import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class CategoryPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final ColorScheme theme;
  final double size;

  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.theme,
    this.size = 250,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validCategories = widget.categories
        .where((cat) => cat['name'] != 'Add Category' && (cat['budget'] as double) > 0)
        .toList();

    if (validCategories.isEmpty) {
      return _buildEmptyState();
    }

    final totalBudget = validCategories.fold<double>(
      0.0, (sum, cat) => sum + (cat['budget'] as double));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            height: widget.size,
            width: widget.size,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: DonutPieChartPainter(
                    categories: validCategories,
                    totalBudget: totalBudget,
                    animationValue: _animation.value,
                    theme: widget.theme,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 18),
        _CategoryLegend(
          categories: validCategories,
          totalBudget: totalBudget,
          theme: widget.theme,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.theme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(widget.size / 2),
        border: Border.all(
          color: widget.theme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: widget.theme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 12),
            Text(
              'No Budget Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.theme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Set budgets for categories to see the chart',
              style: TextStyle(
                fontSize: 12,
                color: widget.theme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DonutPieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double totalBudget;
  final double animationValue;
  final ColorScheme theme;

  DonutPieChartPainter({
    required this.categories,
    required this.totalBudget,
    required this.animationValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalBudget <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 * 0.95;
    final innerRadius = outerRadius * 0.60;
    final chartColors = AppTheme.getChartColors(theme);
    double startAngle = -math.pi / 2; // Start from top

    // Draw donut segments
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final budget = category['budget'] as double;
      final sweepAngle = (budget / totalBudget) * 2 * math.pi * animationValue;
      final paint = Paint()
        ..color = chartColors[i % chartColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius;
      final rect = Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      // Draw category name on the arc, horizontal and further out
      if (sweepAngle > 0.15) { // Only label if the segment is big enough
        final midAngle = startAngle + sweepAngle / 2;
        final labelRadius = outerRadius + 28; // further out, but not rotated
        final labelX = center.dx + labelRadius * math.cos(midAngle);
        final labelY = center.dy + labelRadius * math.sin(midAngle);
        final label = category['name'] as String;
        final labelPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
              shadows: [Shadow(blurRadius: 2, color: Colors.white, offset: Offset(0,0))],
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 80);
        final labelOffset = Offset(
          labelX - labelPainter.width / 2,
          labelY - labelPainter.height / 2,
        );
        labelPainter.paint(canvas, labelOffset);
      }
      startAngle += sweepAngle;
    }

    // Draw inner circle (center info background)
    final innerPaint = Paint()
      ..color = theme.surface.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius - 2, innerPaint);

    // Draw center info (total budget, category count)
    final textPainter1 = TextPainter(
      text: TextSpan(
        text: 'Total Budget',
        style: TextStyle(
          fontSize: 13,
          color: theme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRadius * 1.5);
    final textPainter2 = TextPainter(
      text: TextSpan(
        text: '${totalBudget.toStringAsFixed(0)} LE',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.onSurface,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRadius * 1.5);
    final textPainter3 = TextPainter(
      text: TextSpan(
        text: '${categories.length} Categories',
        style: TextStyle(
          fontSize: 12,
          color: theme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRadius * 1.5);
    final centerY = center.dy - textPainter1.height / 2 - 8;
    textPainter1.paint(canvas, Offset(center.dx - textPainter1.width / 2, centerY));
    textPainter2.paint(canvas, Offset(center.dx - textPainter2.width / 2, centerY + textPainter1.height + 2));
    textPainter3.paint(canvas, Offset(center.dx - textPainter3.width / 2, centerY + textPainter1.height + textPainter2.height + 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final double totalBudget;
  final ColorScheme theme;

  const _CategoryLegend({
    required this.categories,
    required this.totalBudget,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox.shrink();
    final chartColors = AppTheme.getChartColors(theme);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        for (int i = 0; i < categories.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: chartColors[i % chartColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                categories[i]['name'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.onSurface,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '${totalBudget > 0 ? ((categories[i]['budget'] as double) / totalBudget * 100).toStringAsFixed(1) : '0'}%',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
      ],
    );
  }
} 