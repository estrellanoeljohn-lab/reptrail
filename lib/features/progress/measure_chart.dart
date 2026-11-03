import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

typedef MeasurePoint = ({DateTime date, double value});

class MeasureChart extends StatelessWidget {
  const MeasureChart({super.key, required this.points, required this.label});

  final List<MeasurePoint> points;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label chart, from ${points.first.value.toStringAsFixed(1)} '
          'to ${points.last.value.toStringAsFixed(1)} centimeters',
      child: SizedBox(
        height: 90,
        width: double.infinity,
        child: CustomPaint(painter: _MeasurePainter(points)),
      ),
    );
  }
}

class _MeasurePainter extends CustomPainter {
  _MeasurePainter(this.points);

  final List<MeasurePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final start = points.first.date;
    final totalHours =
        math.max(points.last.date.difference(start).inHours, 1);

    var lo = points.map((p) => p.value).reduce(math.min);
    var hi = points.map((p) => p.value).reduce(math.max);
    if (hi - lo < 1) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
    }
    final margin = (hi - lo) * 0.1;
    lo -= margin;
    hi += margin;

    Offset at(MeasurePoint p) {
      final x = pad + p.date.difference(start).inHours / totalHours * w;
      final y = pad + (1 - (p.value - lo) / (hi - lo)) * h;
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = kLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      canvas.drawCircle(at(p), 4, Paint()..color = kLime);
    }
  }

  @override
  bool shouldRepaint(_MeasurePainter old) => old.points != points;
}