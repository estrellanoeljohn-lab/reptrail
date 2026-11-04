import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../profile/profile_repository.dart';
import '../progress/checkin.dart';
import '../progress/checkin_repository.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _arm = TextEditingController();
  final _waist = TextEditingController();
  final _chest = TextEditingController();
  final _thigh = TextEditingController();
  DateTime _date = startOfDay(DateTime.now());
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  @override
  void dispose() {
    _weight.dispose();
    _arm.dispose();
    _waist.dispose();
    _chest.dispose();
    _thigh.dispose();
    super.dispose();
  }

  List<Checkin> get _all => ref.read(checkinsProvider).value ?? const [];

  String _fmt(double? v) => v == null ? '' : v.toStringAsFixed(1);

  /// Fills the form from an existing check-in on the chosen day, so you can
  /// fix a wrong number. Otherwise the form is blank.
  void _prefill() {
    if (!mounted) return;
    final existing =
        _all.where((c) => isSameDay(c.date, _date)).firstOrNull;
    _weight.text = _fmt(existing?.weightKg);
    _arm.text = _fmt(existing?.arm);
    _waist.text = _fmt(existing?.waist);
    _chest.text = _fmt(existing?.chest);
    _thigh.text = _fmt(existing?.thigh);
    setState(() {});
  }

  double? _parse(String? s) =>
      double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  String? _validateWeight(String? v) {
    final n = _parse(v);
    if (n == null) return 'Enter your weight';
    if (n < 30 || n > 300) return 'Enter a weight between 30 and 300 kg';
    return null;
  }

  String? _validateMeasure(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = _parse(v);
    if (n == null) return 'Enter a number';
    if (n < 5 || n > 200) return 'Enter a size between 5 and 200 cm';
    return null;
  }

  Future<void> _pickDate() async {
    final today = startOfDay(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) {
      _date = startOfDay(picked);
      _prefill();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(checkinRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repo.save(
        Checkin(
          date: _date,
          weightKg: _parse(_weight.text)!,
          arm: _parse(_arm.text),
          waist: _parse(_waist.text),
          chest: _parse(_chest.text),
          thigh: _parse(_thigh.text),
        ),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not save. Check your connection and Firestore rules.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _measureField(
    String label,
    TextEditingController controller,
    double? Function(Checkin) pick,
  ) {
    String? hint;
    for (final c in _all.reversed) {
      final v = pick(c);
      if (v != null && c.date.isBefore(_date)) {
        hint = 'Last: ${v.toStringAsFixed(1)}';
        break;
      }
    }
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, helperText: hint),
      validator: _validateMeasure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hideWeight = ref.watch(hideWeightProvider);
    final lastWeight = _all.where((c) => c.date.isBefore(_date)).lastOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(formatWeekdayDate(_date)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      helperText: (lastWeight == null || hideWeight)
                          ? null
                          : 'Last check-in: ${lastWeight.weightKg.toStringAsFixed(1)} kg',
                    ),
                    validator: _validateWeight,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Measurements (cm). Once a week is enough.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _measureField('Arm', _arm, (c) => c.arm)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _measureField('Waist', _waist, (c) => c.waist),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _measureField('Chest', _chest, (c) => c.chest),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _measureField('Thigh', _thigh, (c) => c.thigh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tip: measure at the same time of day and the same spot each time.',
                    style: TextStyle(fontSize: 13, color: kMuted),
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
                        : const Text('Save check-in'),
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