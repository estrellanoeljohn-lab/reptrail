import 'checkin.dart';

/// A body measurement that belongs to a focus area.
class Measure {
  const Measure({required this.label, required this.pick});

  final String label;
  final double? Function(Checkin) pick;
}

Measure? measureForArea(String area) {
  return switch (area) {
    'Arms' => Measure(label: 'Arm', pick: (c) => c.arm),
    'Legs' => Measure(label: 'Thigh', pick: (c) => c.thigh),
    'Chest' => Measure(label: 'Chest', pick: (c) => c.chest),
    _ => null,
  };
}