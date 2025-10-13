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
import 'package:knowledge_recsys/services/session_manager.dart';
import 'package:knowledge_recsys/theme.dart';

//	############################################################################
//	COSTANTI E VARIABILI

enum SyncState { synced, notSynced, offline, error }

enum HomeRouteAction { userRatings, switchTheme, openSettings, logout }

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
  await SessionManager.init();

  // debugPaintSizeEnabled = true;
  runApp(RecSysApp(router: router));
}

//	############################################################################
//	CLASSI E ROUTE

class RecSysApp extends StatefulWidget {
  final GoRouter router;

  const RecSysApp({super.key, required this.router});

  @override
  State<RecSysApp> createState() => _RecSysAppState();
}

class _RecSysAppState extends State<RecSysApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = createTextTheme(context, "DM Sans", "Oswald");
    final materialTheme = MaterialTheme(textTheme);

    return ThemeController(
      toggleTheme: _toggleTheme,
      child: MaterialApp.router(
        title: 'Knowledge-based Recommender System',
        routerConfig: widget.router,
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: materialTheme.light(),
        darkTheme: materialTheme.dark(),
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
