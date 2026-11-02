import '../goal/goal.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.hideWeight,
    this.goal,
  });

  final String name;
  final String email;
  final bool hideWeight;
  final Goal? goal;

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    final g = m['goal'];
    return UserProfile(
      name: (m['name'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      hideWeight: (m['hideWeight'] as bool?) ?? false,
      goal: g is Map<String, dynamic> ? Goal.fromMap(g) : null,
    );
  }
}