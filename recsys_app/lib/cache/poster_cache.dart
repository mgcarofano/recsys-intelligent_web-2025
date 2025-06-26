/*

	poster_cache.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe PosterCache gestisce la cache delle immagini dei poster dei movies,
  consentendo di memorizzare e recuperare le immagini in base all'ID del film
  in modo efficiente, senza doverle scaricare nuovamente ogni volta.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:typed_data';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class PosterCache {
  static final Map<String, Uint8List?> _cache = {};

  static Uint8List? get(String movieId) => _cache[movieId];

  static void set(String movieId, Uint8List? data) {
    _cache[movieId] = data;
  }

  static bool contains(String movieId) => _cache.containsKey(movieId);
}

//	############################################################################
//	RIFERIMENTI
