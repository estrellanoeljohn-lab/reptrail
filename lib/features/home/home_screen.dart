import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_repository.dart';
import '../goal/goal.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final goal = profile?.goal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RepTrail'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Log out'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hi, ${profile?.name ?? ''}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          const SizedBox(height: 16),
          if (goal != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.type.label.toUpperCase(),
                    style: const TextStyle(
                      color: kLime,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${goal.startWeightKg.toStringAsFixed(1)} kg → '
                    '${goal.targetWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Target date: ${formatShortDate(goal.targetDate)}',
                    style: const TextStyle(color: kMuted),
                  ),
                  if (goal.focusAreas.isNotEmpty)
                    Text(
                      'Focus: ${goal.focusAreas.join(', ')}',
                      style: const TextStyle(color: kMuted),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}