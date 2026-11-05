import '../../core/dates.dart';
import '../goal/goal.dart';
import '../progress/checkin.dart';
import '../progress/compare_math.dart';
import '../progress/measures.dart';
import '../progress/progress_math.dart';

class FocusChange {
  const FocusChange({
    required this.area,
    required this.label,
    required this.delta,
  });

  final String area;
  final String label;
  final double delta;
}

class WeekReview {
  const WeekReview({
    required this.start,
    required this.end,
    required this.weekNumber,
    required this.daysElapsed,
    required this.checkinDays,
    required this.measuredDays,
    required this.trendChangeKg,
    required this.rateKgPerWeek,
    required this.weightForPace,
    required this.status,
    required this.focus,
  });

  final DateTime start;
  final DateTime end;
  final int weekNumber;
  final int daysElapsed;
  final int checkinDays;
  final int measuredDays;
  final double? trendChangeKg;
  final double? rateKgPerWeek;
  final double weightForPace;
  final PaceStatus status;
  final List<FocusChange> focus;
}

/// The Monday of the week that contains [d].
DateTime weekStartOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Reviews one Monday to Sunday week. [weekOffset] 0 is this week, -1 is
/// last week, and so on. [sorted] must be oldest first.
WeekReview buildWeekReview({
  required List<Checkin> sorted,
  required Goal goal,
  required DateTime now,
  int weekOffset = 0,
}) {
  final thisWeek = weekStartOf(now);
  final start =
      DateTime(thisWeek.year, thisWeek.month, thisWeek.day + weekOffset * 7);
  final end = DateTime(start.year, start.month, start.day + 6);
  final today = startOfDay(now);
  final asOf = end.isAfter(today) ? today : end;
  final daysElapsed =
      ((asOf.difference(start).inHours / 24).round() + 1).clamp(1, 7).toInt();

  final inWeek = [
    for (final c in sorted)
      if (!c.date.isBefore(start) && !c.date.isAfter(end)) c,
  ];

  final trend = movingAverage(sorted);
  final prevEnd = DateTime(start.year, start.month, start.day - 1);
  final atEnd = trendOn(trend, asOf);
  final atPrev = trendOn(trend, prevEnd) ??
      (inWeek.length >= 2 ? trendOn(trend, inWeek.first.date) : null);
  final trendChange = (inWeek.isNotEmpty && atEnd != null && atPrev != null)
      ? atEnd.weightKg - atPrev.weightKg
      : null;

  final upTo = trend.where((p) => !p.date.isAfter(asOf)).toList();
  final rate = weeklyRate(upTo, asOf);
  final weightForPace = atEnd?.weightKg ?? goal.startWeightKg;
  final status = inWeek.isEmpty
      ? PaceStatus.notEnoughData
      : paceStatus(goal: goal, kgPerWeek: rate, weightKg: weightForPace);

  final focus = <FocusChange>[];
  for (final area in goal.focusAreas) {
    final measure = measureForArea(area);
    if (measure == null) continue;
    final measuredThisWeek = inWeek.any((c) => measure.pick(c) != null);
    final latest = valueOnOrBefore(sorted, asOf, measure.pick);
    final previousValues =
        inWeek.where((c) => measure.pick(c) != null).toList();
    final before = valueOnOrBefore(sorted, prevEnd, measure.pick) ??
        (previousValues.length >= 2
            ? measure.pick(previousValues.first)
            : null);
    if (measuredThisWeek && latest != null && before != null) {
      focus.add(FocusChange(
        area: area,
        label: measure.label,
        delta: latest - before,
      ));
    }
  }

  final measuredDays = inWeek
      .where((c) =>
          c.arm != null ||
          c.waist != null ||
          c.chest != null ||
          c.thigh != null)
      .length;

  final first = weekStartOf(goal.startDate);
  final number = (start.difference(first).inHours / 24 / 7).round() + 1;

  return WeekReview(
    start: start,
    end: end,
    weekNumber: number < 1 ? 1 : number,
    daysElapsed: daysElapsed,
    checkinDays: inWeek.length,
    measuredDays: measuredDays,
    trendChangeKg: trendChange,
    rateKgPerWeek: rate,
    weightForPace: weightForPace,
    status: status,
    focus: focus,
  );
}

/// Up to three short tips for the coming week.
List<String> nextWeekTips(WeekReview r) {
  final tips = <String>[];

  final wanted = r.daysElapsed < 5 ? r.daysElapsed : 5;
  if (r.checkinDays < wanted) {
    tips.add('Check in on more days. Daily weights make your trend more accurate.');
  }
  if (r.measuredDays == 0) {
    tips.add('Measure your arm, waist, chest, and thigh once this week.');
  }

  switch (r.status) {
    case PaceStatus.onTrack:
      tips.add('Your pace is within the guide. Keep doing what you are doing.');
    case PaceStatus.tooFast:
      tips.add('Slow down a little. A steady pace is easier to keep.');
    case PaceStatus.tooSlow:
      tips.add('Progress is slower than the guide. Small, steady changes add up.');
    case PaceStatus.wrongDirection:
      tips.add('Your trend is moving away from your goal. Look at what changed this week.');
    case PaceStatus.notEnoughData:
      if (r.checkinDays >= wanted) {
        tips.add('Check in on 3 or more days over a week to see your pace.');
      }
    case PaceStatus.noGuide:
      break;
  }

  if (tips.isEmpty) tips.add('Keep doing what you are doing.');
  return tips.take(3).toList();
}
