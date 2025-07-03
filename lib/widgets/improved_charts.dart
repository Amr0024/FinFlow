import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../data/monthly_report_data.dart';

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

enum ChartType { axis, pie, bar, line }

class InteractiveAxisChart extends StatefulWidget {
  final List<ChartData> data;
  final double height;
  final bool animate;
  final bool showValues;
  final ColorScheme theme;
  final String xAxisLabel;
  final String yAxisLabel;
  final bool isMonthly;

  const InteractiveAxisChart({
    Key? key,
    required this.data,
    this.height = 300,
    this.animate = true,
    this.showValues = true,
    required this.theme,
    this.xAxisLabel = 'Weeks',
    this.yAxisLabel = 'Savings (LE)',
    this.isMonthly = false,
  }) : super(key: key);

  @override
  State<InteractiveAxisChart> createState() => _InteractiveAxisChartState();
}

class _InteractiveAxisChartState extends State<InteractiveAxisChart>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final maxValue = widget.data.fold(0.0, (max, item) => math.max(max, item.value));
    final chartHeight = widget.height - 80;
    final chartWidth = MediaQuery.of(context).size.width - 80;
    
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Y-axis label
          Text(
            widget.yAxisLabel,
            style: TextStyle(
              color: widget.theme.onBackground,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          // Chart area
          Expanded(
            child: Row(
              children: [
                // Y-axis
                SizedBox(
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final value = (maxValue / 4) * (4 - index);
                      return Text(
                        '${value.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: widget.theme.onBackground.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      );
                    }),
                  ),
                ),
                
                // Chart content
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(chartWidth, chartHeight),
                        painter: AxisChartPainter(
                          data: widget.data,
                          maxValue: maxValue,
                          animationValue: _animation.value,
                          hoveredIndex: _hoveredIndex,
                          theme: widget.theme,
                          isMonthly: widget.isMonthly,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // X-axis label
          Text(
            widget.xAxisLabel,
            style: TextStyle(
              color: widget.theme.onBackground,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AxisChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double maxValue;
  final double animationValue;
  final int? hoveredIndex;
  final ColorScheme theme;
  final bool isMonthly;

  AxisChartPainter({
    required this.data,
    required this.maxValue,
    required this.animationValue,
    this.hoveredIndex,
    required this.theme,
    required this.isMonthly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [theme.primary.withOpacity(0.3), theme.secondary.withOpacity(0.1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final barWidth = size.width / data.length;
    final barSpacing = barWidth * 0.2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = (item.value / maxValue) * size.height * animationValue;
      final x = i * barWidth + barSpacing / 2;
      final y = size.height - barHeight;

      // Draw bar
      final barRect = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      );
      
      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            item.color,
            item.color.withOpacity(0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth - barSpacing, barHeight))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth - barSpacing, barHeight),
          const Radius.circular(8),
        ),
        barPaint,
      );

      // Draw border for hovered bar
      if (hoveredIndex == i) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barWidth - barSpacing, barHeight),
            const Radius.circular(8),
          ),
          borderPaint,
        );
      }

      // Draw value label
      if (barHeight > 30) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${item.value.toStringAsFixed(0)}',
            style: TextStyle(
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
            x + (barWidth - barSpacing) / 2 - textPainter.width / 2,
            y - textPainter.height - 5,
          ),
        );
      }

      // Draw x-axis label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            color: theme.onBackground.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          x + (barWidth - barSpacing) / 2 - labelPainter.width / 2,
          size.height + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ChartTypeSelector extends StatelessWidget {
  final ChartType selectedType;
  final Function(ChartType) onTypeChanged;
  final ColorScheme theme;

  const ChartTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartTypes = [
      {'type': ChartType.axis, 'icon': Icons.bar_chart, 'label': 'Axis'},
      {'type': ChartType.pie, 'icon': Icons.pie_chart, 'label': 'Pie'},
      {'type': ChartType.bar, 'icon': Icons.insert_chart, 'label': 'Bar'},
      {'type': ChartType.line, 'icon': Icons.show_chart, 'label': 'Line'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: chartTypes.map((chartType) {
        final isSelected = selectedType == chartType['type'];
        return GestureDetector(
          onTap: () => onTypeChanged(chartType['type'] as ChartType),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? AppTheme.getPrimaryGradient(theme)
                  : LinearGradient(
                      colors: [
                        theme.primary.withOpacity(0.1),
                        theme.secondary.withOpacity(0.1),
                      ],
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.primary : theme.primary.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: theme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Icon(
              chartType['icon'] as IconData,
              color: isSelected ? Colors.white : theme.primary,
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class InteractivePieChart extends StatefulWidget {
  final List<ChartData> data;
  final double size;
  final bool showLabels;
  final bool showValues;
  final ColorScheme theme;

  const InteractivePieChart({
    Key? key,
    required this.data,
    this.size = 200,
    this.showLabels = true,
    this.showValues = true,
    required this.theme,
  }) : super(key: key);

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    if (widget.data.isEmpty || widget.data.fold(0.0, (sum, item) => sum + item.value) == 0) {
      return Container(
        height: widget.size,
        width: widget.size,
        alignment: Alignment.center,
        child: Text(
          'No data to display',
          style: TextStyle(color: widget.theme.onBackground.withOpacity(0.7)),
        ),
      );
    }
    final total = widget.data.fold(0.0, (sum, item) => sum + item.value);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onTapUp: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final center = Offset(widget.size / 2, widget.size / 2);
            final radius = widget.size / 2;
            
            final distance = (localPosition - center).distance;
            if (distance <= radius) {
              final angle = math.atan2(
                localPosition.dy - center.dy,
                localPosition.dx - center.dx,
              );
              final normalizedAngle = (angle + math.pi) % (2 * math.pi);
              
              double currentAngle = 0;
              for (int i = 0; i < widget.data.length; i++) {
                final sliceAngle = (widget.data[i].value / total) * 2 * math.pi;
                if (normalizedAngle >= currentAngle && 
                    normalizedAngle <= currentAngle + sliceAngle) {
                  setState(() {
                    _hoveredIndex = i;
                  });
                  _showDataTooltip(widget.data[i]);
                  break;
                }
                currentAngle += sliceAngle;
              }
            }
          },
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: InteractivePieChartPainter(
              data: widget.data,
              total: total,
              animationValue: _animation.value,
              showLabels: widget.showLabels,
              showValues: widget.showValues,
              hoveredIndex: _hoveredIndex,
              theme: widget.theme,
            ),
          ),
        );
      },
    );
  }

  void _showDataTooltip(ChartData data) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.getPrimaryGradient(widget.theme),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.icon != null) ...[
                Icon(data.icon, color: Colors.white, size: 24),
                const SizedBox(height: 8),
              ],
              Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.value.toStringAsFixed(0)} LE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

class InteractivePieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double total;
  final double animationValue;
  final bool showLabels;
  final bool showValues;
  final int? hoveredIndex;
  final ColorScheme theme;

  InteractivePieChartPainter({
    required this.data,
    required this.total,
    required this.animationValue,
    required this.showLabels,
    required this.showValues,
    this.hoveredIndex,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi * animationValue;
      
      // Determine if this slice is hovered
      final isHovered = hoveredIndex == i;
      final sliceRadius = isHovered ? radius + 5 : radius;
      
      // Create gradient for the slice
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            item.color,
            item.color.withOpacity(0.7),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: sliceRadius))
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: sliceRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3 : 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: sliceRadius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // Draw labels and values
      if (showLabels || showValues) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = sliceRadius * 0.7;
        final labelX = center.dx + labelRadius * math.cos(labelAngle);
        final labelY = center.dy + labelRadius * math.sin(labelAngle);
        
        String displayText = '';
        if (showLabels && showValues) {
          displayText = '${item.label}\n${item.value.toStringAsFixed(0)} LE';
        } else if (showLabels) {
          displayText = item.label;
        } else if (showValues) {
          displayText = '${item.value.toStringAsFixed(0)} LE';
        }
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: displayText,
            style: TextStyle(
              color: Colors.white,
              fontSize: isHovered ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
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
  final ColorScheme theme;

  const AnimatedBarChart({
    Key? key,
    required this.data,
    this.height = 200,
    this.animate = true,
    this.showValues = true,
    required this.theme,
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
        duration: Duration(milliseconds: 800 + (index * 150)),
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
        Future.delayed(Duration(milliseconds: i * 150), () {
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
    
    return Stack(
      children: [
        CustomPaint(
          size: Size(widget.data.length * 40.0, widget.height),
          painter: _BarChartAxesPainter(data: widget.data, theme: widget.theme, height: widget.height),
        ),
        Container(
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
                  
                  return GestureDetector(
                    onTap: () => _showBarTooltip(item),
                    child: Container(
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
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.showValues && barHeight > 30
                            ? RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  '${item.value.toStringAsFixed(0)} LE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showBarTooltip(ChartData data) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.getPrimaryGradient(widget.theme),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.icon != null) ...[
                Icon(data.icon, color: Colors.white, size: 20),
                const SizedBox(height: 4),
              ],
              Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${data.value.toStringAsFixed(0)} LE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _BarChartAxesPainter extends CustomPainter {
  final List<ChartData> data;
  final ColorScheme theme;
  final double height;

  const _BarChartAxesPainter({
    required this.data,
    required this.theme,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [theme.primary.withOpacity(0.3), theme.secondary.withOpacity(0.1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final barWidth = size.width / data.length;
    final barSpacing = barWidth * 0.2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = (item.value / data.fold(0.0, (max, item) => math.max(max, item.value))) * size.height;
      final x = i * barWidth + barSpacing / 2;
      final y = size.height - barHeight;

      // Draw bar
      final barRect = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      );
      
      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            item.color,
            item.color.withOpacity(0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth - barSpacing, barHeight))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth - barSpacing, barHeight),
          const Radius.circular(8),
        ),
        barPaint,
      );

      // Draw border for hovered bar
      if (i == data.length - 1) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barWidth - barSpacing, barHeight),
            const Radius.circular(8),
          ),
          borderPaint,
        );
      }

      // Draw value label
      if (barHeight > 30) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${item.value.toStringAsFixed(0)} LE',
            style: TextStyle(
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
            x + (barWidth - barSpacing) / 2 - textPainter.width / 2,
            y - textPainter.height - 5,
          ),
        );
      }

      // Draw x-axis label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            color: theme.onBackground.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          x + (barWidth - barSpacing) / 2 - labelPainter.width / 2,
          size.height + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper methods to generate chart data from MonthlyReportData
class ChartDataFactory {
  /// Pie chart: Category breakdown
  static List<ChartData> pieFromCategories(MonthlyReportData data, ColorScheme theme) {
    final chartColors = AppTheme.getChartColors(theme);
    return List.generate(data.categories.length, (i) {
      final cat = data.categories[i];
      return ChartData(
        label: cat.name,
        value: cat.percent,
        color: chartColors[i % chartColors.length],
      );
    });
  }

  /// Bar chart: None Priority Expanses (mocked as totalExpenses for now)
  static List<ChartData> barFromNonPriority(MonthlyReportData data, ColorScheme theme) {
    final chartColors = AppTheme.getChartColors(theme);
    return List.generate(data.months.length, (i) {
      return ChartData(
        label: data.months[i],
        value: data.totalExpenses[i],
        color: chartColors[i % chartColors.length],
      );
    });
  }

  /// Line chart: Savings graph (monthly savings)
  static List<ChartData> lineFromSavings(MonthlyReportData data, ColorScheme theme) {
    final chartColors = AppTheme.getChartColors(theme);
    return List.generate(data.months.length, (i) {
      return ChartData(
        label: data.months[i],
        value: data.totalSavings[i],
        color: chartColors[i % chartColors.length],
      );
    });
  }

  /// Grouped bar chart: Savings vs Expenses per month
  static List<List<ChartData>> groupedBarSavingsVsExpenses(MonthlyReportData data, ColorScheme theme) {
    final chartColors = AppTheme.getChartColors(theme);
    return [
      // Savings
      List.generate(data.months.length, (i) => ChartData(
        label: data.months[i],
        value: data.totalSavings[i],
        color: chartColors[0],
      )),
      // Expenses
      List.generate(data.months.length, (i) => ChartData(
        label: data.months[i],
        value: data.totalExpenses[i],
        color: chartColors[1 % chartColors.length],
      )),
    ];
  }
} 