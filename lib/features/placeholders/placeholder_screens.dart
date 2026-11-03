import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_repository.dart';

class _Soon extends StatelessWidget {
  const _Soon(this.title, this.text);

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(text, style: const TextStyle(color: kMuted)),
      ),
    );
  }
}

class LiftsScreen extends StatelessWidget {
  const LiftsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Soon('Lifts', 'Lift log coming later');
}

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            profile?.name ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(profile?.email ?? '', style: const TextStyle(color: kMuted)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}