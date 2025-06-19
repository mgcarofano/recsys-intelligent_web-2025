/*

	recsys_main.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:knowledge_recsys/services/app_router.dart';

//	############################################################################
//	COSTANTI E VARIABILI

final storage = FlutterSecureStorage();

enum SyncState { synced, notSynced, offline, error }

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	MAIN

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final router = await AppRouter.instance.router;

  runApp(RecSysApp(router: router));
}

//	############################################################################
//	CLASSI E ROUTE

class RecSysApp extends StatelessWidget {
  final GoRouter router;

  const RecSysApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Knowledge-based Recommender System',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
    );
  }
}

//	############################################################################
//	RIFERIMENTI
