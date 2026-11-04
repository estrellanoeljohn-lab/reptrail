import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../goal/goal.dart';
import 'profile_repository.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final goal = profile?.goal;
    final uid = ref.watch(userProvider).value?.uid;
    final hide = profile?.hideWeight ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              profile?.name ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(profile?.email ?? '', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 20),
            if (goal != null)
              _Panel(
                title: 'Your goal',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hide
                          ? goal.type.label
                          : '${goal.type.label} · '
                              '${goal.startWeightKg.toStringAsFixed(1)} → '
                              '${goal.targetWeightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target date: ${formatShortDate(goal.targetDate)}',
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push('/goal/edit'),
                      child: const Text('Change goal'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _Panel(
              title: 'Privacy',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide my weight numbers'),
                subtitle: const Text(
                  'Hides your weight on Home, Compare, and check-ins. '
                  'Changes and trends still show.',
                  style: TextStyle(color: kMuted),
                ),
                value: hide,
                onChanged: uid == null
                    ? null
                    : (v) => ref
                        .read(profileRepositoryProvider)
                        .setHideWeight(uid, v),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/review'),
              child: const Text('Weekly review'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Log out'),
            ),
            const SizedBox(height: 20),
            const Text(
              'RepTrail is a personal tracker. It is not medical advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}