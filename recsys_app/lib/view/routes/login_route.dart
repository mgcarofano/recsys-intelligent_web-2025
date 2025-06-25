/*

	login_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe LoginRoute rappresenta la schermata di login dell'applicazione,
  dove l'utente può scegliere se testare l'applicazione con:
  - una simulazione automatica a partire dai rating di uno specifico utente
  del dataset MovieLens Small, oppure
  - una simulazione manuale, che parte da un'inizializzazione random delle
  preferenze.
  L'utente viene reindirizzato alla schermata principale dell'applicazione una
  volta effettuato l'accesso.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      // showDialog(
      //   barrierDismissible: false,
      //   context: context,
      //   builder: (dialogContext) => PopScope(
      //     onPopInvokedWithResult: (didPop, _) => Future.value(false),
      //     child: const RecSysLoadingDialog(alertMessage: 'Login in corso...'),
      //   ),
      // );

      final userID = userIDController.value.text;

      _loginFormKey.currentState!.reset();
      userIDController.clear();

      if (!mounted) return;

      if (true) {
        // TODO: controllare se esiste l'utente
        // TODO: convertire String in Int
        context.go('/home', extra: userID);
      }
      // else {
      //   context.pop();
      //   ScaffoldMessenger.of(context)
      //     ..hideCurrentSnackBar()
      //     ..showSnackBar(
      //       SnackBar(
      //         behavior: SnackBarBehavior.floating,
      //         content: Text('Utente non trovato!'),
      //         duration: const Duration(seconds: 3),
      //       ),
      //     );
      // }
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
          double containerWidth = constraints.maxWidth * 0.4;
          containerWidth = math.max(400, containerWidth);
          return Center(
            child: Container(
              width: containerWidth,
              padding: EdgeInsets.all(20.0),
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
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
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "Vuoi testare l'applicazione manualmente? ",
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(),
                              ),
                              TextSpan(
                                text: "Clicca qui",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (!mounted) return;
                                    context.go('/home', extra: 0);
                                  },
                              ),
                            ],
                          ),
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
                    ), // User ID
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
