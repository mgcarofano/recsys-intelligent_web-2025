/*

	login_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe LoginRoute rappresenta la schermata di login dell'applicazione,
  dove l'utente può inserire le proprie credenziali per accedere al sistema.
  La logica di autenticazione è implementata localmente e memorizza le
  credenziali dell'utente in modo sicuro per un accesso rapido in futuro.
  L'utente viene reindirizzato alla schermata principale dell'applicazione una
  volta effettuato l'accesso.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

import 'package:knowledge_recsys/services/validators.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_text_form_field.dart';

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
  final _loginFormKey = GlobalKey<FormState>();

  var _isObscured = true;
  var _autovalidateMode = AutovalidateMode.disabled;

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

      _loginFormKey.currentState!.reset();
      emailController.clear();
      passwordController.clear();

      if (!mounted) return;

      context.go('/home', extra: 'Benvenuto!');
    } else {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
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
                autovalidateMode: _autovalidateMode,
                child: Column(
                  spacing: 15.0,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      spacing: 5.0,
                      children: [
                        Text(
                          "Bentornato!",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(),
                          textAlign: TextAlign.center,
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Non hai ancora un account? ",
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(),
                              ),
                              TextSpan(
                                text: "Registrati",
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
                                    context.go('/signup');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    RecSysTextFormField(
                      validator: (value) {
                        final isEmailValid = Validators.validateEmail(
                          value as String,
                        );
                        if (!(isEmailValid == CheckTypes.validValue))
                          switch (isEmailValid) {
                            case CheckTypes.emptyValue:
                              return "Attenzione! L'indirizzo e-mail è obbligatorio";
                            case CheckTypes.notValidPatternEmail:
                              return "Attenzione! L'indirizzo e-mail inserito non è valido";
                            default:
                              return null;
                          }
                        return null;
                      },
                      controller: emailController,
                      prefixIcon: Icons.mail,
                      labelText: 'E-mail *',
                      textInputAction: TextInputAction.next,
                    ), // E-mail
                    RecSysTextFormField(
                      validator: (value) =>
                          Validators.isEmptyValue(value as String) ==
                              CheckTypes.emptyValue
                          ? 'Attenzione! La password è obbligatoria'
                          : null,
                      controller: passwordController,
                      prefixIcon: Icons.lock,
                      labelText: 'Password *',
                      isObscured: _isObscured,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility : Icons.visibility_off,
                          size: 25.0,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        onPressed: () =>
                            setState(() => _isObscured = !_isObscured),
                      ),
                      textInputAction: TextInputAction.done,
                    ), // Password
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
