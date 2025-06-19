/*

	app_router.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

  ...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/view/screens/error_screen.dart';
import 'package:knowledge_recsys/view/routes/home_route.dart';
import 'package:knowledge_recsys/view/routes/login_route.dart';
import 'package:knowledge_recsys/view/routes/movie_route.dart';
import 'package:knowledge_recsys/view/routes/settings_route.dart';
import 'package:knowledge_recsys/view/routes/user_route.dart';

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
    String isUserLoggedIn = await storage.read(key: 'ISUSERLOGGEDIN') ?? '';

    // Widget homeRoute = isUserLoggedIn == 'SI'
    //     ? const HomeRoute()
    //     : const LoginRoute();
    Widget homeRoute = const HomeRoute();

    return GoRouter(
      initialLocation: '/',
      // redirect: (context, state) {
      //   if (isUserLoggedIn == 'SI') {
      //     return '/home';
      //   } else {
      //     return '/';
      //   }
      // },
      routes: [
        GoRoute(
          name: 'LOGIN',
          path: '/',
          builder: (context, state) => const LoginRoute(),
        ),
        GoRoute(
          name: 'HOME',
          path: '/home',
          builder: (context, state) => homeRoute,
        ),
        GoRoute(
          name: 'USER',
          path: '/user',
          builder: (context, state) => const UserRoute(),
        ),
        GoRoute(
          name: 'MOVIE',
          path: '/movie/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return MovieRoute(movieId: id!);
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
