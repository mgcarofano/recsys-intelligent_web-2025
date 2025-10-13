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
import 'package:knowledge_recsys/services/session_manager.dart';

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
      redirect: (context, state) {
        final isLoggingIn = state.matchedLocation == '/login';
        final isHome = state.matchedLocation.startsWith('/home');
        // debugPrint("isLoggingIn: $isLoggingIn, isHome: $isHome, userId: ${SessionManager.isLoggedIn}");

        // Se l'utente non è loggato e tenta di accedere alla home.
        if (!SessionManager.isLoggedIn && isHome) {
          return '/login';
        }

        // Se è loggato e tenta di accedere al login.
        if (SessionManager.isLoggedIn && isLoggingIn) {
          return '/home/${SessionManager.userId}';
        }

        // Nessun redirect necessario
        return null;
      },
      routerNeglect: true,
      routes: [
        GoRoute(
          name: 'LOGIN',
          path: '/login',
          builder: (context, state) => const LoginRoute(),
        ),
        GoRoute(
          name: 'HOME',
          path: '/home/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];

            // Caso 1: ID non valido.
            if (id == null || id.isEmpty)
              return ErrorScreen(errorMessage: "ID utente non valido");

            // Caso 2: utente non loggato.
            if (!SessionManager.isLoggedIn) return const LoginRoute();

            // Caso 3: ID diverso da quello salvato.
            if (id != SessionManager.userId)
              return ErrorScreen(errorMessage: "ID utente non valido");

            return HomeRoute(userId: id);
          },
        ),
        GoRoute(
          name: 'MOVIE',
          path: '/movie/:id',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is Movie) return MovieRoute(movie: extra);

            return ErrorScreen(
              errorMessage:
                  'Impossibile caricare la pagina "Informazioni film".',
              onPressed: () {
                if (!context.mounted) return;
                if (context.canPop()) context.pop();
              },
              buttonText: 'Torna indietro',
            );
          },
        ),
        GoRoute(
          name: 'FEATURE',
          path: '/feature/:id',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is Map && extra['feature'] is Feature) {
              final feature = extra['feature'] as Feature;

              return MovieQueryRoute(
                queryType: 'feature',
                extras: {
                  'feature': feature,
                  'recommendedIds': extra['recommendedIds'],
                },
              );
            }

            return ErrorScreen(
              errorMessage: 'Impossibile caricare la pagina "Mostra tutto".',
              onPressed: () {
                if (!context.mounted) return;
                if (context.canPop()) context.pop();
              },
              buttonText: 'Torna indietro',
            );
          },
        ),
        GoRoute(
          name: 'RATINGS',
          path: '/ratings',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is Map<String, dynamic>)
              return MovieQueryRoute(queryType: 'ratings', extras: extra);

            return ErrorScreen(
              errorMessage:
                  'Impossibile caricare la pagina "Le tue valutazioni".',
              onPressed: () {
                if (!context.mounted) return;
                if (context.canPop()) context.pop();
              },
              buttonText: 'Torna indietro',
            );
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
