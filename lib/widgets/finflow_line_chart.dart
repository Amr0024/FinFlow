import 'package:flutter/material.dart';
import 'dart:math';

class FinFlowLineChart extends StatefulWidget {
  final List<double> savingsData;
  final List<String> monthLabels;
  final ColorScheme theme;

  const FinFlowLineChart({
    Key? key,
    required this.savingsData,
    required this.monthLabels,
    required this.theme,
  }) : super(key: key);

  @override
  _FinFlowLineChartState createState() => _FinFlowLineChartState();
}

class _FinFlowLineChartState extends State<FinFlowLineChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final index = _getTappedIndex(localPosition, constraints.maxWidth);
            setState(() => selectedIndex = index);
          },
          child: AspectRatio(
            aspectRatio: 1.5,
            child: CustomPaint(
              painter: _SavingsChartPainter(
                widget.savingsData,
                widget.monthLabels,
                selectedIndex,
                _getThemeLineColor(widget.theme),
                constraints,
              ),
            ),
          ),
        );
      },
    );
  }

  int? _getTappedIndex(Offset position, double width) {
    final margin = 70.0;
    final chartWidth = width - margin * 2;
    final spacing = chartWidth / (widget.savingsData.length - 1);
    for (int i = 0; i < widget.savingsData.length; i++) {
      final x = margin + i * spacing;
      if ((position.dx - x).abs() < 25) return i;
    }
    return null;
  }

  Color _getThemeLineColor(ColorScheme theme) {
    // Use AppTheme's sunsetPurple and oceanBlue primary colors for robust detection
    if (theme.primary.value == 0xFF1E3A8A) {
      // Ocean Blue theme
      return const Color(0xFF4DD0E1).withOpacity(0.7); // Light cyan
    } else if (theme.primary.value == 0xFF7C3AED) {
      // Sunset Purple theme
      return const Color(0xFFFFC04D).withOpacity(0.85); // Lighter orange
    } else {
      return Color.lerp(theme.primary, Colors.white, 0.45)!;
    }
  }
}

class _SavingsChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> months;
  final int? selectedIndex;
  final Color lineColor;
  final BoxConstraints constraints;

  _SavingsChartPainter(this.data, this.months, this.selectedIndex, this.lineColor, this.constraints);

  @override
  void paint(Canvas canvas, Size size) {
    final leftPaddingForYAxis = 55.0;
    final topMargin = 20.0;
    final bottomMargin = 50.0;
    final rightMargin = 20.0;

    final chartWidth = size.width - leftPaddingForYAxis - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    final spacing = chartWidth / (data.length - 1);
    // Zoom in: set minY and maxY to fit the data more closely
    final minY = (data.reduce(min) / 1.2).floorToDouble();
    final maxY = (data.reduce(max) * 1.1).ceilToDouble();
    final scaleY = chartHeight / (maxY - minY);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final dotPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (double x = leftPaddingForYAxis; x < size.width - rightMargin; x += 20) {
      for (double y = topMargin; y < size.height - bottomMargin; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Calculate ySteps dynamically for zoomed range
    final yStep = ((maxY - minY) / 4).clamp(100, 1000);
    final ySteps = List.generate(5, (i) => (minY + i * yStep).round());
    // Always show 0 as the lowest Y-axis value and at the bottom
    ySteps[0] = 0;
    final labelStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black); // Bigger
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.right);

    for (int i = 0; i < ySteps.length; i++) {
      final yVal = ySteps[i];
      double y;
      if (yVal == 0) {
        y = size.height - bottomMargin;
      } else {
        y = topMargin + chartHeight - ((yVal - minY) * scaleY);
      }
      // Only draw grid and label if y is within the chart area
      if (y >= topMargin && y <= size.height - bottomMargin) {
        canvas.drawLine(Offset(leftPaddingForYAxis, y), Offset(size.width - rightMargin, y), gridPaint);
        final label = yVal >= 1000 ? '${(yVal / 1000).toStringAsFixed(1).replaceAll('.0', '')}k' : yVal.toString();
        tp.text = TextSpan(text: label, style: labelStyle);
        tp.layout();
        tp.paint(canvas, Offset(leftPaddingForYAxis - tp.width - 18, y - tp.height / 2));
      }
    }

    final points = List.generate(data.length, (i) {
      final x = leftPaddingForYAxis + i * spacing;
      final y = topMargin + chartHeight - ((data[i] - minY) * scaleY);
      return Offset(x, y);
    });

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 8 // Thicker for clarity
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    // Fill area
    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height - bottomMargin)
      ..lineTo(points.first.dx, size.height - bottomMargin)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.45), lineColor.withOpacity(0.12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, topMargin, size.width, chartHeight));

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 12, pointPaint); // Bigger points
    }

    // X axis months
    final xLabelStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black); // Bigger
    for (int i = 0; i < months.length; i++) {
      final label = months[i];
      tp.text = TextSpan(text: label, style: xLabelStyle);
      tp.layout();
      final x = leftPaddingForYAxis + i * spacing;
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomMargin + 12));
    }

    // Tooltip
    if (selectedIndex != null) {
      final point = points[selectedIndex!];

      // Dotted guide
      final dashWidth = 4;
      final dashSpace = 4;
      double startY = topMargin;
      while (startY < size.height - bottomMargin) {
        canvas.drawLine(
          Offset(point.dx, startY),
          Offset(point.dx, startY + dashWidth),
          Paint()..color = Colors.grey..strokeWidth = 1,
        );
        startY += dashWidth + dashSpace;
      }

      // Highlight
      canvas.drawCircle(point, 22, Paint()
        ..color = lineColor.withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(point, 16, Paint()..color = lineColor);

      // Tooltip text
      final value = data[selectedIndex!].toInt();
      tp.text = TextSpan(text: '$value LE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
      tp.layout();
      final tooltipW = tp.width + 20;
      final tooltipH = tp.height + 12;
      final tooltipRect = Rect.fromLTWH(point.dx - tooltipW / 2, point.dy - 50, tooltipW, tooltipH);

      canvas.drawRRect(
        RRect.fromRectAndRadius(tooltipRect, Radius.circular(6)),
        Paint()..color = Colors.black,
      );
      tp.paint(canvas, Offset(tooltipRect.left + 10, tooltipRect.top + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 