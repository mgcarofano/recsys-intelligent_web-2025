/*

	carousel_model.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

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

import 'package:knowledge_recsys/model/movie_model.dart';

class Carousel {
  final String category;
  final String featureName;
  final double featureRating;
  final List<String> allIds;
  final List<Movie> movies;
  final Map<String, Map<String, dynamic>> nerdStats;

  Carousel({
    required this.category,
    required this.featureName,
    required this.featureRating,
    required this.allIds,
    required this.movies,
    required this.nerdStats,
  });

  Carousel copyWith({List<Movie>? movies}) {
    return Carousel(
      category: category,
      featureName: featureName,
      featureRating: featureRating,
      allIds: allIds,
      movies: movies ?? this.movies,
      nerdStats: nerdStats,
    );
  }

  @override
  String toString() {
    return '''Carousel{
      category: $category,
      featureName: $featureName,
      featureRating: $featureRating,
      allIds: $allIds
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
