import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_notifier.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/circles/views/circle_detail_screen.dart';
import '../../features/circles/views/circles_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/matching/views/compare_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/plans/views/plan_detail_screen.dart';
import '../../features/plans/views/plans_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/rota_import/views/rota_import_screen.dart';
import '../../features/schedule/views/schedule_screen.dart';
import 'main_shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// Listenable that notifies GoRouter whenever the Riverpod AuthState changes
class AuthChangeNotifier extends ChangeNotifier {
  final Ref _ref;

  AuthChangeNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      // While initial token check is running, do not force redirect
      if (authState.status == AuthStatus.initial) {
        return null;
      }

      // If user is unauthenticated, send them to login unless already on auth screens
      if (!authState.isAuthenticated) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // If authenticated user tries to open login or register, route to dashboard
      if (isLoggingIn || isRegistering) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Notifications Route
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Rota Import Route
      GoRoute(
        path: '/rota-import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RotaImportScreen(),
      ),

      // Circle Detail Route
      GoRoute(
        path: '/circles/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return CircleDetailScreen(circleId: id);
        },
      ),

      // Plan Detail Route
      GoRoute(
        path: '/plans/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return PlanDetailScreen(planId: id);
        },
      ),

      // Stateful Shell Route for Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Schedule
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),

          // Branch 2: Circles
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/circles',
                builder: (context, state) => const CirclesScreen(),
              ),
            ],
          ),

          // Branch 3: Compare
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/compare',
                builder: (context, state) {
                  final circleId = int.tryParse(state.uri.queryParameters['circle'] ?? '');
                  return CompareScreen(initialCircleId: circleId);
                },
              ),
            ],
          ),

          // Branch 4: Plans
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (context, state) {
                  final isCreate = state.uri.queryParameters['create'] == 'true';
                  final circleId = int.tryParse(state.uri.queryParameters['circle'] ?? '');
                  final date = state.uri.queryParameters['date'];
                  final start = state.uri.queryParameters['start'];
                  final end = state.uri.queryParameters['end'];

                  return PlansScreen(
                    autoOpenCreate: isCreate,
                    initialCircleId: circleId,
                    initialDate: date,
                    initialStart: start,
                    initialEnd: end,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
