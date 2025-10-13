/*

	error_screen.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe ErrorScreen visualizza un messaggio di errore generico quando si
  verifica un problema durante la navigazione o il caricamento di una schermata
  dell'applicazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/services/session_manager.dart';
import 'package:knowledge_recsys/view/widgets/recsys_alert_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onPressed;
  final String? buttonText;

  const ErrorScreen({
    super.key,
    this.errorMessage,
    this.onPressed,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RecSysAppBar(
        title: 'Knowledge-based Recommender System',
        alignment: Alignment.topCenter,
        isBackActive: false,
      ),
      resizeToAvoidBottomInset: false,
      body: RecSysAlertDialog(
        topIcon: Icons.warning_amber_sharp,
        alertTitle: 'Attenzione',
        alertContent: Text(errorMessage ?? 'Prova a spegnere e riaccendere!'),
        isCancelActive: false,
        onPressConfirm:
            onPressed ??
            () {
              SessionManager.logout();
              context.replace('/login');
            },
        confirmText: buttonText ?? 'Torna al login',
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
