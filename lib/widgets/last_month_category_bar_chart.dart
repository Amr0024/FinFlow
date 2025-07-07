import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class LastMonthCategoryBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final ColorScheme theme;
  final double height;

  const LastMonthCategoryBarChart({
    super.key,
    required this.categories,
    required this.theme,
    this.height = 300,
  });

  @override
  State<LastMonthCategoryBarChart> createState() => _LastMonthCategoryBarChartState();
}

class _LastMonthCategoryBarChartState extends State<LastMonthCategoryBarChart> with SingleTickerProviderStateMixin {
  late List<_BarData> _barData;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _generateDemoData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  void _generateDemoData() {
    final random = math.Random(42); // fixed seed for consistent demo
    final cats = widget.categories.where((c) => c['name'] != 'Add Category').toList();
    _barData = cats.map((cat) {
      // Generate a random expense between 1000 and 5000
      final value = 1000 + random.nextInt(4000);
      return _BarData(
        name: cat['name'] as String,
        value: value.toDouble(),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant LastMonthCategoryBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories.length != widget.categories.length) {
      _generateDemoData();
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme;
    final chartColors = AppTheme.getChartColors(colorScheme);
    final maxValue = _barData.map((b) => b.value).fold<double>(0, math.max);
    final minY = 0.0;
    final maxY = maxValue > 0 ? (maxValue / 1000).ceil() * 1000 : 5000;
    final chartHeight = widget.height - 60;
    final gridLineCount = 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barCount = _barData.length;
                final spacing = 8.0;
                final chartWidth = constraints.maxWidth - 32.0 - 32.0; // more even left/right padding
                final barWidth = barCount > 0 ? (chartWidth - (barCount - 1) * spacing) / barCount : 0.0;
                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Center(
                      child: CustomPaint(
                        size: Size(chartWidth + 32.0 + 32.0, widget.height),
                        painter: _BarChartPainter(
                          barData: _barData,
                          chartColors: chartColors,
                          animationValue: _animation.value,
                          minY: minY,
                          maxY: maxY.toDouble(),
                          barWidth: barWidth,
                          spacing: spacing,
                          chartHeight: chartHeight,
                          gridLineCount: gridLineCount,
                          colorScheme: colorScheme,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String name;
  final double value;
  _BarData({required this.name, required this.value});
}

class _BarChartPainter extends CustomPainter {
  final List<_BarData> barData;
  final List<Color> chartColors;
  final double animationValue;
  final double minY;
  final double maxY;
  final double barWidth;
  final double spacing;
  final double chartHeight;
  final int gridLineCount;
  final ColorScheme colorScheme;

  _BarChartPainter({
    required this.barData,
    required this.chartColors,
    required this.animationValue,
    required this.minY,
    required this.maxY,
    required this.barWidth,
    required this.spacing,
    required this.chartHeight,
    required this.gridLineCount,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 64.0;
    final bottomPadding = 36.0;
    final topPadding = 16.0;
    final rightPadding = 32.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final barCount = barData.length;
    final totalBarSpace = barCount * barWidth + (barCount - 1) * spacing;
    final startX = leftPadding + (chartWidth - totalBarSpace) / 2;

    // Draw grid lines and Y axis labels
    final gridPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.13)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      fontSize: 13,
      color: colorScheme.onSurface.withOpacity(0.7),
    );
    for (int i = 0; i <= gridLineCount; i++) {
      final y = topPadding + chartHeight * (1 - i / gridLineCount);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
      final value = minY + (maxY - minY) * i / gridLineCount;
      final valueStr = value % 1000 == 0 ? value.toInt().toString() : value.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: valueStr, style: labelStyle),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPadding - 28);
      tp.paint(canvas, Offset(leftPadding - tp.width - 28, y - tp.height / 2));
    }

    // Draw Y axis label
    final yLabel = TextPainter(
      text: TextSpan(
        text: 'Expenses',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    canvas.save();
    canvas.translate(-18, topPadding + chartHeight / 2 + yLabel.width / 2);
    canvas.rotate(-math.pi / 2);
    yLabel.paint(canvas, Offset(0, 0));
    canvas.restore();

    // Draw X axis labels and bars
    for (int i = 0; i < barData.length; i++) {
      final bar = barData[i];
      final x = startX + i * (barWidth + spacing);
      final barHeight = ((bar.value - minY) / (maxY - minY) * chartHeight) * animationValue;
      final barTop = topPadding + chartHeight - barHeight;
      final barRect = Rect.fromLTWH(x, barTop, barWidth, barHeight);
      final barPaint = Paint()
        ..color = chartColors[i % chartColors.length].withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(8)),
        barPaint,
      );
      // Draw category name (rotated)
      final labelTp = TextPainter(
        text: TextSpan(
          text: bar.name,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth + 40);
      canvas.save();
      canvas.translate(x + barWidth / 2, topPadding + chartHeight + 8 + labelTp.width / 2);
      canvas.rotate(-math.pi / 4);
      labelTp.paint(canvas, Offset(-labelTp.width / 2, 0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 