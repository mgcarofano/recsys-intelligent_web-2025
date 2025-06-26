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
  final String title;
  final String description;
  final List<String> subjects;

  Movie({
    required this.idMovie,
    required this.title,
    required this.description,
    required this.subjects,
  });

  @override
  String toString() {
    return 'Documento{id: $idMovie, titolo: $title, descrizione: $subjects, size: $subjects}';
  }
}

//	############################################################################
//	RIFERIMENTI
