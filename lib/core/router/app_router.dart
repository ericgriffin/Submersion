import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dive_log/presentation/pages/dive_list_page.dart';
import '../../features/dive_log/presentation/pages/dive_detail_page.dart';
import '../../features/dive_log/presentation/pages/dive_edit_page.dart';
import '../../features/dive_sites/presentation/pages/site_list_page.dart';
import '../../features/dive_sites/presentation/pages/site_detail_page.dart';
import '../../features/dive_sites/presentation/pages/site_edit_page.dart';
import '../../features/gear/presentation/pages/gear_list_page.dart';
import '../../features/gear/presentation/pages/gear_detail_page.dart';
import '../../features/gear/presentation/pages/gear_edit_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dives',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Dive Log
          GoRoute(
            path: '/dives',
            name: 'dives',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiveListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newDive',
                builder: (context, state) => const DiveEditPage(),
              ),
              GoRoute(
                path: ':diveId',
                name: 'diveDetail',
                builder: (context, state) => DiveDetailPage(
                  diveId: state.pathParameters['diveId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'editDive',
                    builder: (context, state) => DiveEditPage(
                      diveId: state.pathParameters['diveId'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Dive Sites
          GoRoute(
            path: '/sites',
            name: 'sites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SiteListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newSite',
                builder: (context, state) => const SiteEditPage(),
              ),
              GoRoute(
                path: ':siteId',
                name: 'siteDetail',
                builder: (context, state) => SiteDetailPage(
                  siteId: state.pathParameters['siteId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'editSite',
                    builder: (context, state) => SiteEditPage(
                      siteId: state.pathParameters['siteId'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Gear
          GoRoute(
            path: '/gear',
            name: 'gear',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GearListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newGear',
                builder: (context, state) => const GearEditPage(),
              ),
              GoRoute(
                path: ':gearId',
                name: 'gearDetail',
                builder: (context, state) => GearDetailPage(
                  gearId: state.pathParameters['gearId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'editGear',
                    builder: (context, state) => GearEditPage(
                      gearId: state.pathParameters['gearId'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Statistics
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatisticsPage(),
            ),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
});