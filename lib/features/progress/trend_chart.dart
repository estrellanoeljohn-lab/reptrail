import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'checkin.dart';
import 'progress_math.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.checkins, required this.trend});

  final List<Checkin> checkins;
  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final first = checkins.first.weightKg.toStringAsFixed(1);
    final last = checkins.last.weightKg.toStringAsFixed(1);
    return Semantics(
      label: 'Weight trend chart, from $first to $last kilograms',
      child: SizedBox(
        height: 90,
        width: double.infinity,
        child: CustomPaint(painter: _TrendPainter(checkins, trend)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.raw, this.trend);

  final List<Checkin> raw;
  final List<TrendPoint> trend;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 6.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final start = raw.first.date;
    final totalHours = math.max(raw.last.date.difference(start).inHours, 1);

    final values = <double>[
      for (final c in raw) c.weightKg,
      for (final t in trend) t.weightKg,
    ];
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 0.5) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
    }
    final margin = (hi - lo) * 0.1;
    lo -= margin;
    hi += margin;

    Offset point(DateTime d, double v) {
      final x = pad + d.difference(start).inHours / totalHours * w;
      final y = pad + (1 - (v - lo) / (hi - lo)) * h;
      return Offset(x, y);
    }

    // Thin line: the daily weights.
    final rawPath = Path();
    for (var i = 0; i < raw.length; i++) {
      final p = point(raw[i].date, raw[i].weightKg);
      if (i == 0) {
        rawPath.moveTo(p.dx, p.dy);
      } else {
        rawPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      rawPath,
      Paint()
        ..color = const Color(0xFF6B7690)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Bright line: the 7-day average.
    final trendPath = Path();
    for (var i = 0; i < trend.length; i++) {
      final p = point(trend[i].date, trend[i].weightKg);
      if (i == 0) {
        trendPath.moveTo(p.dx, p.dy);
      } else {
        trendPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      trendPath,
      Paint()
        ..color = kLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.raw != raw || old.trend != trend;
}