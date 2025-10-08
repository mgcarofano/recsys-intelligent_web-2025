/*

	ratings_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class RatingsRoute extends StatefulWidget {
  const RatingsRoute({super.key});

  @override
  State<RatingsRoute> createState() => _RatingsRouteState();
}

class _RatingsRouteState extends State<RatingsRoute> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: RecSysAppBar(
        title: 'Le tue valutazioni',
        alignment: Alignment.topLeft,
      ),
      resizeToAvoidBottomInset: false,
      body: Center(child: Text('Ratings')),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
