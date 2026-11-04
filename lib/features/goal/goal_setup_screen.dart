import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_repository.dart';
import 'goal.dart';
import 'pace.dart';

const _focusOptions = ['Arms', 'Legs', 'Chest', 'Back', 'Core', 'Shoulders'];

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key, this.editing = false});

  /// True when changing an existing goal from the Me screen.
  final bool editing;

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _target = TextEditingController();
  GoalType _type = GoalType.cut;
  DateTime _targetDate =
      startOfDay(DateTime.now()).add(const Duration(days: 84));
  final Set<String> _focus = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(profileProvider).value?.goal;
    if (widget.editing && goal != null) {
      _type = goal.type;
      _current.text = goal.startWeightKg.toStringAsFixed(1);
      _target.text = goal.targetWeightKg.toStringAsFixed(1);
      _targetDate = goal.targetDate;
      _focus.addAll(goal.focusAreas);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _target.dispose();
    super.dispose();
  }

  double? _parse(String? s) =>
      double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  String? _validateWeight(String? v) {
    final n = _parse(v);
    if (n == null) return 'Enter a number';
    if (n < 30 || n > 300) return 'Enter a weight between 30 and 300 kg';
    return null;
  }

  String? _validateTarget(String? v) {
    final base = _validateWeight(v);
    if (base != null) return base;
    final current = _parse(_current.text);
    final target = _parse(v)!;
    if (current == null) return null;
    if (_type == GoalType.cut && target >= current) {
      return 'Target must be lower than your starting weight';
    }
    if (_type == GoalType.bulk && target <= current) {
      return 'Target must be higher than your starting weight';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final today = startOfDay(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.isBefore(today) ? today : _targetDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final today = startOfDay(DateTime.now());
    if (_targetDate.difference(today).inDays < 7) {
      setState(() => _error = 'Pick a target date at least a week away.');
      return;
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    // When editing, keep the original start so progress keeps counting.
    final keep = widget.editing ? ref.read(profileProvider).value?.goal : null;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).saveGoal(
            uid,
            Goal(
              type: _type,
              startWeightKg: keep?.startWeightKg ?? _parse(_current.text)!,
              targetWeightKg: _parse(_target.text)!,
              startDate: keep?.startDate ?? today,
              targetDate: _targetDate,
              focusAreas: _focusOptions.where(_focus.contains).toList(),
            ),
          );
      // When setting up for the first time, the router moves you to Home.
      if (widget.editing && mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not save your goal. Check your connection and Firestore rules.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _paceCard() {
    final current = _parse(_current.text);
    final target = _parse(_target.text);
    if (current == null || target == null) return const SizedBox.shrink();

    final days = _targetDate.difference(startOfDay(DateTime.now())).inDays;
    final children = <Widget>[];

    if (days < 7) {
      children.add(const Text('Pick a target date at least a week away.'));
    } else {
      final perWeek =
          plannedKgPerWeek(currentKg: current, targetKg: target, days: days);
      final range = suggestedPace(_type, current);
      final weeks = (days / 7).round();

      if (range != null) {
        children.add(Text(
          'Suggested pace: ${range.minKgPerWeek.toStringAsFixed(1)} to '
          '${range.maxKgPerWeek.toStringAsFixed(1)} kg per week',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ));
      }
      children.add(Text(
        'Your plan: ${(target - current).abs().toStringAsFixed(1)} kg in '
        '$weeks weeks is ${perWeek.abs().toStringAsFixed(1)} kg per week.',
      ));
      if (range != null) {
        final message = switch (judgePace(range, perWeek)) {
          PaceVerdict.withinRange => 'That is within the suggested pace.',
          PaceVerdict.tooFast =>
            'That is faster than the suggested pace. A slower plan is easier to keep.',
          PaceVerdict.tooSlow =>
            'That is slower than the suggested pace. It works, but it may take longer.',
        };
        children.add(Text(message));
      } else {
        children.add(const Text('A pace guide applies to cut and bulk goals.'));
      }
    }
    children.add(const Text(
      'A guide only, not medical advice.',
      style: TextStyle(fontSize: 12, color: kMuted),
    ));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            children[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.editing ? AppBar(title: const Text('Change goal')) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, widget.editing ? 8 : 32, 24, 32),
                children: [
                  if (!widget.editing) ...[
                    const Text(
                      'Set your goal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'We use this to tell you if you are on track.',
                      style: TextStyle(fontSize: 15, color: kMuted, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                  ],
                  const Text(
                    'Goal type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (final t in GoalType.values)
                        _GoalOption(
                          label: t.label,
                          selected: _type == t,
                          onTap: () => setState(() => _type = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _type.hint,
                    style: const TextStyle(fontSize: 13, color: kMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _current,
                          enabled: !widget.editing,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: widget.editing
                                ? 'Starting weight (kg)'
                                : 'Current weight (kg)',
                            helperText: widget.editing
                                ? 'Stays the same so your progress keeps counting.'
                                : null,
                            helperMaxLines: 2,
                          ),
                          validator: _validateWeight,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _target,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Target weight (kg)',
                          ),
                          validator: _validateTarget,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Target date',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(formatWeekdayDate(_targetDate)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Focus areas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final area in _focusOptions)
                        FilterChip(
                          label: Text(area),
                          selected: _focus.contains(area),
                          onSelected: (on) => setState(() {
                            if (on) {
                              _focus.add(area);
                            } else {
                              _focus.remove(area);
                            }
                          }),
                        ),
                    ],
                  ),
                  _paceCard(),
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
                        : Text(widget.editing ? 'Save changes' : 'Start tracking'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: selected ? kLime : kLine),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? kLimeTint : kCard,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? kLime : kText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}