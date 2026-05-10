import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vision_companion/features/analyzer/pages/analyzer_page.dart';
import 'package:vision_companion/features/auth/cubit/auth_cubit.dart';
import 'package:vision_companion/features/auth/cubit/auth_state.dart';
import 'package:vision_companion/features/auth/pages/login_page.dart';
import 'package:vision_companion/features/auth/pages/signup_page.dart';
import 'package:vision_companion/features/detector/pages/detector_page.dart';
import 'package:vision_companion/features/history/pages/history_page.dart';
import 'package:vision_companion/features/home/pages/home_page.dart';
import 'package:vision_companion/features/settings/pages/settings_page.dart';

class AppRouter {
  static GoRouter router(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/login',
      observers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final isAuthenticated = authCubit.state is AuthAuthenticated;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (!isAuthenticated && !isAuthRoute) return '/login';
        if (isAuthenticated && isAuthRoute) return '/home';
        return null;
      },

      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
        GoRoute(path: '/detector', builder: (_, __) => const DetectorPage()),
        GoRoute(path: '/analyzer', builder: (_, __) => const AnalyzerPage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
