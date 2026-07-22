import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/crash/presentation/screens/crash_screen.dart';
import '../../features/crossing/presentation/screens/crossing_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/lobby/presentation/screens/lobby_screen.dart';
import '../../features/missions/presentation/screens/missions_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/purchase_info/presentation/screens/how_to_buy_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/scratch/presentation/screens/scratch_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/app_shell_screen.dart';
import '../../features/slot/presentation/screens/home_screen.dart';
import '../../features/store/presentation/screens/store_screen.dart';
import '../../features/support/presentation/screens/help_support_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/wheel/presentation/screens/wheel_screen.dart';
import 'route_names.dart';

/// App-wide [GoRouter] configuration.
///
/// The 5 bottom-nav tabs are branches of a single [StatefulShellRoute] so
/// each keeps independent navigation/scroll state. The Home tab is the
/// [LobbyScreen] game hub; each game itself (the slot machine's
/// [HomeScreen], despite the name; [CrashScreen]) is a full-screen flow
/// pushed above the shell like wallet, profile, rewards and achievements.
/// Every cold start hits [SplashScreen] first, which then routes to
/// Onboarding (first launch only) or straight to the Lobby.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
                StatefulNavigationShell navigationShell) =>
            AppShellScreen(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (_, _) => const LobbyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.store,
                name: RouteNames.store,
                builder: (_, _) => const StoreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.leaderboard,
                name: RouteNames.leaderboard,
                builder: (_, _) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.missions,
                name: RouteNames.missions,
                builder: (_, _) => const MissionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.wallet,
        name: RouteNames.wallet,
        builder: (_, _) => const WalletScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.playSlots,
        name: RouteNames.playSlots,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.playCrash,
        name: RouteNames.playCrash,
        builder: (_, _) => const CrashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.playCrossing,
        name: RouteNames.playCrossing,
        builder: (_, _) => const CrossingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.playWheel,
        name: RouteNames.playWheel,
        builder: (_, _) => const WheelScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.playScratch,
        name: RouteNames.playScratch,
        builder: (_, _) => const ScratchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.helpSupport,
        name: RouteNames.helpSupport,
        builder: (_, _) => const HelpSupportScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.howToBuy,
        name: RouteNames.howToBuy,
        builder: (_, _) => const HowToBuyScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.rewards,
        name: RouteNames.rewards,
        builder: (_, _) => const RewardsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.achievements,
        name: RouteNames.achievements,
        builder: (_, _) => const AchievementsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, _) => const SplashScreen(),
      ),
    ],
  );
}
