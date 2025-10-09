/*

	movie_model.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe Movie rappresenta un film, con i suoi metadati principali (es. titolo, descrizione, attori, ...) e viene utilizzata per memorizzare e gestire le informazioni sui film presenti nel database dell'applicazione di raccomandazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

Future<List<Movie>> fetchMoviesFromIds(List<String> ids) async {
  final ret = ids.toSet().map((id) async {
    String? movieInfo = await BaseClient.instance
        .getMovieInfo(idMovie: id)
        .catchError((_) => null);

    Map<String, dynamic> movieMap = toMap(movieInfo ?? '{}');

    final t = safeFirst(movieMap['title']);
    final d = safeFirst(movieMap['description']);

    return Movie(
      idMovie: id,

      title: t ?? "",
      description: d ?? "",

      actors: List<String>.from(movieMap['actors'] ?? []),
      composers: List<String>.from(movieMap['composers'] ?? []),
      directors: List<String>.from(movieMap['directors'] ?? []),
      genres: List<String>.from(movieMap['genres'] ?? []),
      producers: List<String>.from(movieMap['producers'] ?? []),
      productionCompanies: List<String>.from(
        movieMap['production_companies'] ?? [],
      ),
      subjects: List<String>.from(movieMap['subjects'] ?? []),
      writers: List<String>.from(movieMap['writers'] ?? []),

      seen: movieMap['seen'],
      rating: movieMap['rating'],
    );
  }).toList();

  return (await Future.wait(ret)).whereType<Movie>().toList();
}

//	############################################################################
//	CLASSI e ROUTE

class Movie {
  // Identificativo
  final String idMovie;

  // Caratteristiche principali
  final String? title;
  final String? description;

  // Altre caratteristiche
  final List<String>? actors;
  final List<String>? composers;
  final List<String>? directors;
  final List<String>? genres;
  final List<String>? producers;
  final List<String>? productionCompanies;
  final List<String>? subjects;
  final List<String>? writers;

  // Rating
  final bool? seen;
  final double? rating;

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
    this.seen,
    this.rating,
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
      seen: ${(seen ?? false) ? 'Si' : 'No'},
      rating: ${rating ?? ''}
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
