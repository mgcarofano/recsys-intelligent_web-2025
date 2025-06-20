/*

	user_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe UserRoute rappresenta la schermata del profilo utente, dove l'utente
  può visualizzare e modificare le proprie informazioni personali, o gestire le
  preferenze nel sistema di raccomandazione.

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

class UserRoute extends StatefulWidget {
  const UserRoute({super.key});

  @override
  State<UserRoute> createState() => _UserRouteState();
}

class _UserRouteState extends State<UserRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RecSysAppBar(
        title: 'Ciao, ...',
        alignment: Alignment.topLeft,
      ),
      body: const Center(child: Text("User")),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
