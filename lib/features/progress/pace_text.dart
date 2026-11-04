import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../goal/goal.dart';
import '../goal/pace.dart';
import 'progress_math.dart';

const kAmber = Color(0xFFFFB84D);

typedef PaceText = ({String title, String detail, Color color});

PaceText paceText({
  required Goal goal,
  required PaceStatus status,
  required double? rate,
  required double kg,
}) {
  String guide() {
    final range = suggestedPace(goal.type, kg);
    if (range == null) return '';
    final sign = goal.type == GoalType.cut ? -1.0 : 1.0;
    return '${signed(sign * range.minKgPerWeek)} to '
        '${signed(sign * range.maxKgPerWeek)}';
  }

  final r = rate ?? 0;
  return switch (status) {
    PaceStatus.notEnoughData => (
        title: 'Not enough data yet',
        detail: 'Check in on 3 or more days over a week to see your pace.',
        color: kMuted,
      ),
    PaceStatus.onTrack => (
        title: 'On track',
        detail: '${signed(r)} kg per week · goal pace ${guide()}',
        color: kLime,
      ),
    PaceStatus.tooFast => (
        title: 'Faster than the guide',
        detail: '${signed(r)} kg per week. The guide is ${guide()}. '
            'A slower pace is easier to keep.',
        color: kAmber,
      ),
    PaceStatus.tooSlow => (
        title: 'Slower than the guide',
        detail: '${signed(r)} kg per week. The guide is ${guide()}.',
        color: kAmber,
      ),
    PaceStatus.wrongDirection => (
        title: 'Moving the other way',
        detail: goal.type == GoalType.cut
            ? 'Your weight trend is going up. Your goal is to lose weight.'
            : 'Your weight trend is going down. Your goal is to gain weight.',
        color: kAmber,
      ),
    PaceStatus.noGuide => (
        title: 'Weight trend',
        detail: '${signed(r)} kg per week',
        color: kLime,
      ),
  };
}