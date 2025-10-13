/*

	login_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe LoginRoute rappresenta la schermata di login dell'applicazione, dove l'utente può inserire il proprio identificativo per accedere al sistema e inizializzare la piattaforma di raccomandazione in base ai rating che ha fornito. L'utente, quindi, viene reindirizzato alla schermata principale dell'applicazione una volta effettuato l'accesso.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/services/session_manager.dart';
import 'package:knowledge_recsys/services/validators.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';
import 'package:knowledge_recsys/view/widgets/recsys_text_form_field.dart';

//	############################################################################
//	COSTANTI E VARIABILI

var userIDController = TextEditingController();

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
  final _loginFormKey = GlobalKey<FormState>();

  _onSubmit() async {
    if (_loginFormKey.currentState!.validate()) {
      final userID = userIDController.value.text;
      _loginFormKey.currentState!.reset();
      userIDController.clear();

      if (!mounted) return;

      var data = await BaseClient.instance.getUsers().catchError((err) {
        // debugPrint('\n--- ERRORE ---\n$err\n-----\n');
        if (!mounted) return null;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(err.toString()),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        return null;
      });

      // debugPrint("$data");
      if (data == null) return;

      final userList = toList<String>(data);

      if (userList.contains(userID)) {
        BaseClient.instance
            .loginUser(userId: userID)
            .then((_) {
              SessionManager.login(userID);
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/home/$userID');
              });
            })
            .catchError((err) {
              // debugPrint('\n--- ERRORE ---\n$err\n-----\n');
              if (!mounted) return null;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(err.toString()),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              return null;
            });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Utente non trovato!'),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RecSysAppBar(
        title: 'Knowledge-based Recommender System',
        alignment: Alignment.topCenter,
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
              child: Form(
                key: _loginFormKey,
                child: Column(
                  spacing: 15.0,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      spacing: 5.0,
                      children: [
                        Text(
                          "Benvenuto!",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Inserisci il tuo ID utente per iniziare",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    RecSysTextFormField(
                      validator: (value) =>
                          Validators.isEmptyValue(value as String) ==
                              CheckTypes.emptyValue
                          ? 'Attenzione! Il codice utente è obbligatorio'
                          : null,
                      controller: userIDController,
                      prefixIcon: Icons.person,
                      labelText: 'ID utente *',
                      textInputAction: TextInputAction.done,
                    ),
                    ElevatedButton(
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Entra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.fontSize,
                          ),
                        ),
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

//  https://dribbble.com/shots/23424744-Login-Page
//  https://stackoverflow.com/questions/79153827/using-min-width-with-fractionallysizedbox
//  https://stackoverflow.com/questions/48914775/gesture-detection-in-flutter-textspan
