/*

	recsys_main.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	Questo file contiene il punto di ingresso principale del sistema di
  raccomandazione, implementato nella funzione main(). La classe RecSysApp è il
  widget principale che avvia l'applicazione e gestisce la configurazione del
  tema, definito nel file "theme.dart", e della navigazione, definita nel file
  "app_router.dart".

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import 'package:knowledge_recsys/services/app_router.dart';
import 'package:knowledge_recsys/theme.dart';

//	############################################################################
//	COSTANTI E VARIABILI

enum SyncState { synced, notSynced, offline, error }

enum HomeRouteAction { openSettings, logout }

//	############################################################################
//	ALTRI METODI

List<dynamic> toList(String data) {
  return json.decode(data).cast<String>().toList();
}

Map<String, dynamic> toMap(String data) {
  return json.decode(data);
}

//	############################################################################
//	MAIN

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final router = await AppRouter.instance.router;

  // debugPaintSizeEnabled = true;
  runApp(RecSysApp(router: router));
}

//	############################################################################
//	CLASSI E ROUTE

class RecSysApp extends StatelessWidget {
  final GoRouter router;

  const RecSysApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "DM Sans", "Oswald");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      title: 'Knowledge-based Recommender System',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
