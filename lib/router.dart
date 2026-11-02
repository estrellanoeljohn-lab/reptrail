
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/create_account_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/goal/goal_setup_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_repository.dart';

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
    ref.listen(userProvider, (_, _) => refresh.refresh());
  ref.listen(profileProvider, (_, _) => refresh.refresh());

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final atAuth = loc == '/welcome' || loc == '/create-account';

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return atAuth ? null : '/welcome';

      final profile = ref.read(profileProvider);
      if (profile.isLoading) return loc == '/loading' ? null : '/loading';

      final hasGoal = profile.value?.goal != null;
      if (!hasGoal) return loc == '/goal' ? null : '/goal';
      if (atAuth || loc == '/goal' || loc == '/loading') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/goal',
        builder: (context, state) => const GoalSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});