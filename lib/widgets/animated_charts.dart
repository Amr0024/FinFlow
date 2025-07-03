import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedPieChart extends StatefulWidget {
  final List<ChartData> data;
  final double size;
  final bool showLabels;
  final bool animate;

  const AnimatedPieChart({
    Key? key,
    required this.data,
    this.size = 200,
    this.showLabels = true,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class ChartData {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

class _AnimatedPieChartState extends State<AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold(0.0, (sum, item) => sum + item.value);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: PieChartPainter(
            data: widget.data,
            total: total,
            animationValue: _animation.value,
            showLabels: widget.showLabels,
          ),
        );
      },
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double total;
  final double animationValue;
  final bool showLabels;

  PieChartPainter({
    required this.data,
    required this.total,
    required this.animationValue,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    double startAngle = -math.pi / 2; // Start from top
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi * animationValue;
      
      // Draw pie slice
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // Draw labels
      if (showLabels) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.7;
        final labelX = center.dx + labelRadius * math.cos(labelAngle);
        final labelY = center.dy + labelRadius * math.sin(labelAngle);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            labelX - textPainter.width / 2,
            labelY - textPainter.height / 2,
          ),
        );
      }
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedBarChart extends StatefulWidget {
  final List<ChartData> data;
  final double height;
  final bool animate;
  final bool showValues;

  const AnimatedBarChart({
    Key? key,
    required this.data,
    this.height = 200,
    this.animate = true,
    this.showValues = true,
  }) : super(key: key);

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.data.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );
    }).toList();

    if (widget.animate) {
      for (int i = 0; i < _controllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) _controllers[i].forward();
        });
      }
    } else {
      for (var controller in _controllers) {
        controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.data.fold(0.0, (max, item) => math.max(max, item.value));
    
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.data.length, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final item = widget.data[index];
              final barHeight = (item.value / maxValue) * (widget.height - 80) * _animations[index].value;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.showValues)
                    Text(
                      '\$${item.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    width: 30,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.color,
                          item.color.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

class AnimatedLineChart extends StatefulWidget {
  final List<Point> points;
  final double width;
  final double height;
  final Color lineColor;
  final bool showPoints;
  final bool animate;

  const AnimatedLineChart({
    Key? key,
    required this.points,
    this.width = 300,
    this.height = 200,
    this.lineColor = Colors.blue,
    this.showPoints = true,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class Point {
  final double x;
  final double y;
  final String? label;

  Point({required this.x, required this.y, this.label});
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
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
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: LineChartPainter(
            points: widget.points,
            lineColor: widget.lineColor,
            animationValue: _animation.value,
            showPoints: widget.showPoints,
          ),
        );
      },
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<Point> points;
  final Color lineColor;
  final double animationValue;
  final bool showPoints;

  LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.animationValue,
    required this.showPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final maxX = points.fold(0.0, (max, point) => math.max(max, point.x));
    final maxY = points.fold(0.0, (max, point) => math.max(max, point.y));
    final minX = points.fold(double.infinity, (min, point) => math.min(min, point.x));
    final minY = points.fold(double.infinity, (min, point) => math.min(min, point.y));

    final path = Path();
    bool firstPoint = true;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = ((point.x - minX) / (maxX - minX)) * size.width;
      final y = size.height - ((point.y - minY) / (maxY - minY)) * size.height;
      
      final animatedY = size.height - (size.height - y) * animationValue;

      if (firstPoint) {
        path.moveTo(x, animatedY);
        firstPoint = false;
      } else {
        path.lineTo(x, animatedY);
      }

      // Draw points
      if (showPoints) {
        final paint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, animatedY), 4, paint);
        
        // Draw white border
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawCircle(Offset(x, animatedY), 4, borderPaint);
      }
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 