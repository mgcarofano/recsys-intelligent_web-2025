/*

	recsys_loading_dialog.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe RecSysLoadingDialog crea un widget personalizzato che mostra
  l'animazione del caricamento di un processo in corso con un messaggio di
  attesa.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class RecSysLoadingDialog extends StatelessWidget {
  final String alertMessage;

  const RecSysLoadingDialog({super.key, required this.alertMessage});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      ),
      title: Text(alertMessage),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
