/*

	carousel_model.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe Carousel rappresenta un carosello di film raccomandati, associato a una particolare caratteristica (feature) del sistema di raccomandazione. La classe Carousel viene utilizzata per organizzare e visualizzare le raccomandazioni di film in modo strutturato e intuitivo per l'utente.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

import 'package:knowledge_recsys/model/feature_model.dart';
import 'package:knowledge_recsys/model/movie_model.dart';

class Carousel {
  final Feature feature;
  final List<String> allIds;
  final List<Movie> movies;
  final Map<String, Map<String, dynamic>> nerdStats;

  Carousel({
    required this.feature,
    required this.allIds,
    required this.movies,
    required this.nerdStats,
  });

  Carousel copyWith({List<Movie>? movies}) {
    return Carousel(
      feature: feature,
      allIds: allIds,
      movies: movies ?? this.movies,
      nerdStats: nerdStats,
    );
  }

  @override
  String toString() {
    return '''Carousel{
      feature: $feature,
      nerdStats: $nerdStats,
      allIds: $allIds
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
