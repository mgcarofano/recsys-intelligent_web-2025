/*

	home_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Home"));
  }
}

//	############################################################################
//	RIFERIMENTI
