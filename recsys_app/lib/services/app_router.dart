/*

	app_router.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

  La classe AppRouter gestisce la navigazione dell'applicazione utilizzando il
  pacchetto "go_router".

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/model/feature_model.dart';
import 'package:knowledge_recsys/model/movie_model.dart';

import 'package:knowledge_recsys/view/screens/error_screen.dart';
import 'package:knowledge_recsys/view/routes/login_route.dart';
import 'package:knowledge_recsys/view/routes/home_route.dart';
import 'package:knowledge_recsys/view/routes/movie_info_route.dart';
import 'package:knowledge_recsys/view/routes/movie_query_route.dart';
import 'package:knowledge_recsys/view/routes/settings_route.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class AppRouter {
  AppRouter._privateConstructor();

  static final AppRouter instance = AppRouter._privateConstructor();
  static GoRouter? _router;

  Future<GoRouter> get router async => _router ??= await _initRouter();

  Future<GoRouter> _initRouter() async {
    return GoRouter(
      initialLocation: '/login',
      routerNeglect: true,
      routes: [
        GoRoute(
          name: 'LOGIN',
          path: '/login',
          builder: (context, state) => const LoginRoute(),
        ),
        GoRoute(
          name: 'HOME',
          path: '/home',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is String) return HomeRoute(userId: extra);
            return ErrorScreen();
          },
        ),
        GoRoute(
          name: 'MOVIE',
          path: '/movie/:id',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Movie) return MovieRoute(movie: extra);
            return ErrorScreen();
          },
        ),
        GoRoute(
          name: 'FEATURE',
          path: '/feature/:id',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is Map && extra['feature'] is Feature) {
              final feature = extra['feature'] as Feature;
              final recommendedIds = List<String>.from(
                extra['recommendedIds'] ?? [],
              );

              return MovieQueryRoute(
                queryType: 'feature',
                extras: {'feature': feature, 'recommendedIds': recommendedIds},
              );
            }

            return ErrorScreen();
          },
        ),
        GoRoute(
          name: 'RATINGS',
          path: '/ratings',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is String)
              return MovieQueryRoute(
                queryType: 'ratings',
                extras: {'userId': extra},
              );
            return ErrorScreen();
          },
        ),
        GoRoute(
          name: 'SETTINGS',
          path: '/settings',
          builder: (context, state) => const SettingsRoute(),
        ),
      ],
      errorBuilder: (context, state) => const ErrorScreen(),
    );
  }
}

//	############################################################################
//	RIFERIMENTI

//  https://www.youtube.com/watch?v=hQ7GuKty-gY
