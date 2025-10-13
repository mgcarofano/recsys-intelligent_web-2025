/*

	session_manager.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe SessionManager gestisce lo stato di autenticazione dell'utente
  nell'applicazione, implementando metodi per il login e il logout tramite
  l'uso della libreria SharedPreferences per la persistenza dei dati.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:shared_preferences/shared_preferences.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class SessionManager {
  static String? _userId;

  static String? get userId => _userId;
  static bool get isLoggedIn => _userId != null && _userId!.isNotEmpty;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
  }

  static Future<void> login(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = id;
    await prefs.setString('userId', id);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = null;
    await prefs.remove('userId');
  }
}

//	############################################################################
//	RIFERIMENTI
