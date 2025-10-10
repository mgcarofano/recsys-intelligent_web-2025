/*

	movie_model.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe Movie rappresenta un film, con i suoi metadati principali
  (es. titolo, descrizione, attori, ...) e viene utilizzata per memorizzare
  e gestire le informazioni sui film presenti nel database dell'applicazione
  di raccomandazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

Future<List<Movie>> fetchMoviesFromData(Map<String, dynamic> data) async {
  final ret = data.entries.map((item) async {
    debugPrint("${(item.key).runtimeType}, ${(item.key)}");
    debugPrint("${(item.value).runtimeType}, ${(item.value)}");

    String? movieInfo = await BaseClient.instance
        .getMovieInfo(idMovie: item.key)
        .catchError((_) => null);

    Map<String, dynamic> movieMap = toMap(movieInfo ?? '{}');

    final t = safeFirst(movieMap['title']) ?? "";
    final d = safeFirst(movieMap['description']) ?? "";

    bool? s;
    double? r;
    double? sp;
    if (item.value != null) {
      if (item.value is Map<String, dynamic>) {
        s = item.value['seen'];
        r = item.value['movie_rating'];
        sp = item.value['softmax_prob'];
      } else if (item.value is double?) {
        sp = item.value;
      }
    }

    return Movie(
      idMovie: item.key,

      title: t,
      description: d,

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

      seen: s ?? movieMap['seen'],
      rating: r ?? movieMap['rating'],
      softmaxProb: sp,
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

  // Statistiche per nerd
  final bool? seen;
  final double? rating;
  final double? softmaxProb;

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
    this.softmaxProb,
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
      rating: ${rating ?? ''},
      softmaxProb: ${softmaxProb ?? ''}
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
