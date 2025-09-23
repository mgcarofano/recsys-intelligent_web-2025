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
  final List<String> allIds;
  final List<Movie> movies;

  Carousel({
    required this.category,
    required this.featureName,
    required this.allIds,
    required this.movies,
  });

  Carousel copyWith({List<Movie>? movies}) {
    return Carousel(
      category: category,
      featureName: featureName,
      allIds: allIds,
      movies: movies ?? this.movies,
    );
  }

  @override
  String toString() {
    return '''Carousel{
      category: $category,
      featureName: $featureName,
      allIds: $allIds
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
