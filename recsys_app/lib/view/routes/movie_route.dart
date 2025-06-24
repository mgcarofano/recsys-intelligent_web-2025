/*

	movie_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe MovieRoute rappresenta la schermata dei dettagli di un film, dove
  l'utente può visualizzare le informazioni principali (e.g. titolo,
  descrizione, anno di uscita, ...), una breve spiegazione del motivo per cui
  il film è stato raccomandato e altri parametri più specifici propri del
  sistema di raccomandazione.

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

class MovieRoute extends StatefulWidget {
  final String movieId;

  const MovieRoute({super.key, required this.movieId});

  @override
  State<MovieRoute> createState() => _MovieRouteState();
}

class _MovieRouteState extends State<MovieRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RecSysAppBar(title: widget.movieId, alignment: Alignment.topLeft),
      body: Center(child: Text("Movie")),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
