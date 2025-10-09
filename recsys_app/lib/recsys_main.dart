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

enum HomeRouteAction { userRatings, openSettings, logout }

const int maxColumns = 5;

//	############################################################################
//	ALTRI METODI

List<T> toList<T>(String data) {
  return json.decode(data).cast<T>().toList();
}

Map<String, dynamic> toMap(String data) {
  return json.decode(data);
}

T? safeFirst<T>(List<T>? list) {
  if (list == null || list.isEmpty) return null;
  return list.first;
}

MaterialColor getRatingColor(double rating) {
  if (rating >= 0.0 && rating <= 1.0)
    return Colors.red;
  else if (rating > 1.0 && rating <= 2.0)
    return Colors.orange;
  else if (rating > 2.0 && rating <= 3.0)
    return Colors.amber;
  else if (rating > 3.0 && rating <= 4.0)
    return Colors.lime;
  else if (rating > 4.0 && rating <= 5.0)
    return Colors.green;
  else
    return Colors.amber;
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
