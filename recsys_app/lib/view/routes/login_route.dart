/*

	login_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';

//	############################################################################
//	COSTANTI E VARIABILI

var emailController = TextEditingController();
var passwordController = TextEditingController();

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class LoginRoute extends StatefulWidget {
  const LoginRoute({super.key});

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Login"));
  }
}

//	############################################################################
//	RIFERIMENTI
