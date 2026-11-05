import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import 'lift_log.dart';
import 'lift_math.dart';
import 'lift_repository.dart';
import '../profile/profile_repository.dart';

class LiftsScreen extends ConsumerWidget {
  const LiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(liftLogsProvider).value ?? const <LiftLog>[];
    final prIds = personalRecordLogIds(logs);
    final prCount = personalRecordsInLast30Days(logs, DateTime.now());
    final exerciseNames = <String>{};
    for (final log in logs) {
      exerciseNames.add(log.exercise);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lifts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/lifts/log'),
        icon: const Icon(Icons.add),
        label: const Text('Log a lift'),
      ),
      body: logs.isEmpty
          ? _EmptyLifts(onLog: () => context.push('/lifts/log'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                const Text(
                  'Your training trail',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  prCount == 0
                      ? 'No PRs yet this month'
                      : '$prCount new ${prCount == 1 ? 'PR' : 'PRs'} this month',
                  style: const TextStyle(color: kMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${logs.length} logged ${logs.length == 1 ? 'lift' : 'lifts'}',
                  style: const TextStyle(color: kMuted),
                ),
                const SizedBox(height: 20),
                if (exerciseNames.isNotEmpty) ...[
                  const Text(
                    'Exercises',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in exerciseNames) Chip(label: Text(name)),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],
                const Text(
                  'Recent logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (final log in logs) ...[
                  _LiftLogCard(log: log, isPr: prIds.contains(log.id)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _EmptyLifts extends StatelessWidget {
  const _EmptyLifts({required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: kLimeTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center, color: kLime, size: 32),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your next rep starts here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log a lift to build a record of your strength over time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, height: 1.5),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onLog,
            icon: const Icon(Icons.add),
            label: const Text('Log your first lift'),
          ),
        ],
      ),
    ),
  );
}

class _LiftLogCard extends StatelessWidget {
  const _LiftLogCard({required this.log, required this.isPr});

  final LiftLog log;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    final best = log.bestWeightKg;
    final estimated = bestEstimatedOneRepMax(log);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log.exercise,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isPr)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kLimeTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PR',
                    style: TextStyle(
                      color: kLime,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (isPr) const SizedBox(width: 8),
              Text(
                formatWeekdayDate(log.date),
                style: const TextStyle(fontSize: 12, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${log.sets.length} sets  ·  ${log.volumeKg.toStringAsFixed(0)} kg total volume${best == null ? '' : '  ·  best ${best.toStringAsFixed(1)} kg'}',
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
          if (estimated != null) ...[
            const SizedBox(height: 4),
            Text(
              'est. 1RM ${estimated.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < log.sets.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${i + 1}: ${log.sets[i].weightKg.toStringAsFixed(1)} kg × ${log.sets[i].reps}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              log.notes,
              style: const TextStyle(color: kMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class LogLiftScreen extends ConsumerStatefulWidget {
  const LogLiftScreen({super.key});

  @override
  ConsumerState<LogLiftScreen> createState() => _LogLiftScreenState();
}

class _LogLiftScreenState extends ConsumerState<LogLiftScreen> {
  static const _armExercises = [
    'Hammer curl',
    'Wrist curl',
    'Pronation',
    'Barbell curl',
  ];
  static const _legExercises = ['Squat', 'Leg press'];
  static const _otherExercises = [
    'Bench press',
    'Deadlift',
    'Overhead press',
    'Lat pulldown',
    'Barbell row',
  ];
  final _exercise = TextEditingController();
  final _notes = TextEditingController();
  final List<({TextEditingController weight, TextEditingController reps})>
  _sets = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addSet(weight: '20', reps: '8');
    _addSet(weight: '20', reps: '8');
    _addSet(weight: '20', reps: '8');
  }

  void _addSet({String weight = '', String reps = ''}) => setState(() {
    _sets.add((
      weight: TextEditingController(text: weight),
      reps: TextEditingController(text: reps),
    ));
  });

  void _removeSet(int index) => setState(() {
    _sets[index].weight.dispose();
    _sets[index].reps.dispose();
    _sets.removeAt(index);
  });

  List<LiftSet> _validSets() {
    final result = <LiftSet>[];
    for (final entry in _sets) {
      final weight = double.tryParse(
        entry.weight.text.trim().replaceAll(',', '.'),
      );
      final reps = int.tryParse(entry.reps.text.trim());
      if (weight != null &&
          reps != null &&
          estimatedOneRepMax(weight, reps) != null) {
        result.add(LiftSet(weightKg: weight, reps: reps));
      }
    }
    return result;
  }

  @override
  void dispose() {
    _exercise.dispose();
    _notes.dispose();
    for (final set in _sets) {
      set.weight.dispose();
      set.reps.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _exercise.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the exercise name.');
      return;
    }
    final sets = <LiftSet>[];
    for (var i = 0; i < _sets.length; i++) {
      final weight = double.tryParse(
        _sets[i].weight.text.trim().replaceAll(',', '.'),
      );
      final reps = int.tryParse(_sets[i].reps.text.trim());
      if (weight == null || weight < 0 || reps == null || reps < 1) {
        setState(
          () => _error =
              'Enter a valid weight and at least 1 rep for set ${i + 1}.',
        );
        return;
      }
      sets.add(LiftSet(weightKg: weight, reps: reps));
    }
    final repository = ref.read(liftRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repository.save(
        LiftLog(
          id: '',
          exercise: name,
          date: startOfDay(DateTime.now()),
          sets: sets,
          notes: _notes.text.trim(),
        ),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save this lift. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(liftLogsProvider).value ?? const <LiftLog>[];
    final exercise = normalizedExerciseName(_exercise.text);
    final earlierLogs = logs
        .where(
          (log) =>
              normalizedExerciseName(log.exercise) == exercise &&
              !log.date.isAfter(startOfDay(DateTime.now())),
        )
        .toList();
    final bestEarlier = bestEstimatedOneRepMaxPerExercise(
      earlierLogs,
    )[exercise];
    final liveLog = LiftLog(
      id: '',
      exercise: _exercise.text,
      date: DateTime.now(),
      sets: _validSets(),
    );
    final bestSet = bestEstimatedSet(liveLog);
    final estimate = bestEstimatedOneRepMax(liveLog);
    final isNewPr =
        estimate != null && bestEarlier != null && estimate > bestEarlier;
    final goal = ref.watch(profileProvider).value?.goal;
    final focusAreas = goal?.focusAreas ?? const <String>[];
    final suggestions = focusAreas.any((area) => area.toLowerCase() == 'arms')
        ? [..._armExercises, ..._legExercises, ..._otherExercises]
        : focusAreas.any((area) => area.toLowerCase() == 'legs')
        ? [..._legExercises, ..._armExercises, ..._otherExercises]
        : [
            'Bench press',
            'Squat',
            'Deadlift',
            'Overhead press',
            'Lat pulldown',
            'Barbell row',
            'Leg press',
            ..._armExercises,
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Log a lift')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Record today’s work',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose an exercise and add each working set.',
              style: TextStyle(color: kMuted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _exercise,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Exercise',
                hintText: 'e.g. Bench press',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final name in suggestions)
                  ActionChip(
                    label: Text(name),
                    onPressed: () => setState(() {
                      _exercise.text = name;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sets',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addSet(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add set'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 42),
                const Expanded(
                  child: Text(
                    'Weight (kg)',
                    style: TextStyle(color: kMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reps',
                    style: TextStyle(color: kMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
            for (var i = 0; i < _sets.length; i++) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: kMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _sets[i].weight,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _sets[i].reps,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '8'),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: IconButton(
                      onPressed: _sets.length <= 1 ? null : () => _removeSet(i),
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove set',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNewPr ? kLimeTint : kCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: estimate == null || bestSet == null
                  ? const Text(
                      'Enter a valid set to see your estimated 1RM.',
                      style: TextStyle(color: kMuted),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNewPr)
                          const Text(
                            'New personal record',
                            style: TextStyle(
                              color: kLime,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else if (bestEarlier != null)
                          Text(
                            'Your best: ${bestEarlier.toStringAsFixed(1)} kg',
                            style: const TextStyle(color: kMuted),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Best set: ${bestSet.weightKg.toStringAsFixed(1)} kg × ${bestSet.reps}. Estimated 1RM: ${estimate.toStringAsFixed(1)} kg.',
                          style: TextStyle(
                            color: isNewPr ? kText : kMuted,
                            fontWeight: isNewPr
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did it feel?',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kError)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save lift'),
            ),
          ],
        ),
      ),
    );
  }
}
