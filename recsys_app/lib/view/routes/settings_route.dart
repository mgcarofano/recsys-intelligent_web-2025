/*

	settings_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe SettingsRoute mostra una schermata dove
  l'utente può modificare i parametri del sistema di raccomandazione e altre
  opzioni legate alla personalizzazione dell'esperienza utente.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({super.key});

  @override
  State<SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RecSysAppBar(
        title: 'Impostazioni',
        alignment: Alignment.topLeft,
      ),
      body: const Center(child: Text("Settings")),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
