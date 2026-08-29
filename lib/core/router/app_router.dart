import 'package:ebikemanager/core/router/app_shell.dart';
import 'package:ebikemanager/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ebikemanager/features/history/presentation/history_screen.dart';
import 'package:ebikemanager/features/history/presentation/trip_detail_screen.dart';
import 'package:ebikemanager/features/navigation/presentation/map_screen.dart';
import 'package:ebikemanager/features/profile/presentation/bike_detail_screen.dart';
import 'package:ebikemanager/features/profile/presentation/manage_bikes_screen.dart';
import 'package:ebikemanager/features/profile/presentation/profile_screen.dart';
import 'package:ebikemanager/features/profile/presentation/settings_screen.dart';
import 'package:ebikemanager/features/repair/presentation/repair_guide_detail_screen.dart';
import 'package:ebikemanager/features/repair/presentation/repair_list_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/navigation',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/repair',
                builder: (context, state) => const RepairListScreen(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    builder: (context, state) => RepairGuideDetailScreen(
                      slug: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'trip/:tripId',
                    builder: (context, state) => TripDetailScreen(
                      tripId: state.pathParameters['tripId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'bikes',
                    builder: (context, state) => const ManageBikesScreen(),
                    routes: [
                      GoRoute(
                        path: ':bikeId',
                        builder: (context, state) => BikeDetailScreen(
                          bikeId: state.pathParameters['bikeId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
