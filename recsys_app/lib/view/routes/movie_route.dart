/*

	movie_route.dart
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

class MovieRoute extends StatefulWidget {
  final String movieId;

  MovieRoute({super.key, required this.movieId});

  @override
  State<MovieRoute> createState() => _MovieRouteState();
}

class _MovieRouteState extends State<MovieRoute> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [Text("Movie"), Text(widget.movieId)]),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
