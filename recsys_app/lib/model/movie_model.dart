/*

	movie_model.dart
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

class Movie {
  final String idMovie;
  final String? title;
  final String? description;
  final List<String>? actors;
  final List<String>? composers;
  final List<String>? directors;
  final List<String>? genres;
  final List<String>? producers;
  final List<String>? productionCompanies;
  final List<String>? subjects;
  final List<String>? writers;

  Movie({
    required this.idMovie,
    this.title,
    this.description,
    this.actors,
    this.composers,
    this.directors,
    this.genres,
    this.producers,
    this.productionCompanies,
    this.subjects,
    this.writers,
  });

  @override
  String toString() {
    return '''Movie{
      id: $idMovie,
      title: ${title ?? ''},
      description: ${description ?? ''},
      actors: ${actors ?? ''},
      composers: ${composers ?? ''},
      directors: ${directors ?? ''},
      genres: ${genres ?? ''},
      producers: ${producers ?? ''},
      productionCompanies: ${productionCompanies ?? ''},
      subjects: ${subjects ?? ''},
      writers: ${writers ?? ''},
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
