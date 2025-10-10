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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RecSysAppBar(
        title: 'Knowledge-based Recommender System',
        alignment: Alignment.topLeft,
      ),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double containerWidth = constraints.maxWidth * 0.3;
          containerWidth = math.max(400, containerWidth);
          return Center(
            child: Container(
              width: containerWidth,
              padding: EdgeInsets.all(20.0),
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 15.0,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      spacing: 5.0,
                      children: [
                        Text(
                          "Errore",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Prova a spegnere e riaccendere!",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.replace('/login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Torna al login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.fontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
