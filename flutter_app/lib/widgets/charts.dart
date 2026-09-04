import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../finance_models.dart';

class CategoryPieChart extends StatelessWidget {
  final List<MapEntry<String, double>> slices;
  final double size;

  const CategoryPieChart({
    super.key,
    required this.slices,
    this.size = 128,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, e) => sum + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PiePainter(
          slices: slices,
          total: total <= 0 ? 1 : total,
        ),
      ),
    );
  }
}

class WeeklyBarChart extends StatelessWidget {
  final List<ChartPoint> bars;
  final Color color;
  final double height;

  const WeeklyBarChart({
    super.key,
    required this.bars,
    this.color = const Color(0xFF22AE98),
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = bars.fold<double>(
      0,
      (m, b) => math.max(m, b.amount),
    );
    final scale = maxAmount <= 0 ? 1.0 : maxAmount;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: math.max(0.06, bar.amount / scale),
                          widthFactor: 0.72,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final bar in bars)
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrendSparkline extends StatelessWidget {
  final List<ChartPoint> points;
  final Color color;
  final double height;

  const TrendSparkline({
    super.key,
    required this.points,
    this.color = const Color(0xFFFF7F20),
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: points.map((p) => p.amount).toList(),
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final point in points)
              Text(
                point.label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }
}

class BalanceAreaSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const BalanceAreaSparkline({
    super.key,
    required this.values,
    this.color = const Color(0xFF22AE98),
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _AreaSparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<MapEntry<String, double>> slices;
  final double total;

  _PiePainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final inner = Rect.fromCircle(center: center, radius: radius * 0.58);
    var start = -math.pi / 2;

    if (slices.isEmpty) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        true,
        Paint()..color = const Color(0xFFE8E4DC),
      );
    } else {
      for (var i = 0; i < slices.length; i++) {
        final sweep = (slices[i].value / total) * math.pi * 2;
        canvas.drawArc(
          rect,
          start,
          sweep,
          true,
          Paint()..color = _colorFromHex(categoryOf(slices[i].key).color),
        );
        start += sweep;
      }
    }

    canvas.drawCircle(center, inner.width / 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.total != total;
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final padY = size.height * 0.12;
    final usableH = size.height - padY * 2;
    final stepX = values.length == 1
        ? 0.0
        : size.width / (values.length - 1);

    Offset pointAt(int i) {
      final t = (values[i] - minV) / range;
      return Offset(i * stepX, size.height - padY - (t * usableH));
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _AreaSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _AreaSparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final padY = size.height * 0.15;
    final usableH = size.height - padY * 2;
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final t = (values[i] - minV) / range;
      return Offset(i * stepX, size.height - padY - (t * usableH));
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AreaSparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

Color _colorFromHex(String hexString) {
  final cleaned = hexString.replaceFirst('#', '');
  final value = cleaned.length == 6 ? cleaned : 'FF$cleaned';
  return Color(int.parse(value, radix: 16) + 0xFF000000);
}
