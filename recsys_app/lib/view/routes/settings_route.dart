/*

	settings_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe SettingsRoute mostra una schermata dove l'utente può modificare
  i parametri del sistema di raccomandazione e altre opzioni legate alla
  personalizzazione dell'esperienza utente.

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
import 'package:knowledge_recsys/services/validators.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_text_form_field.dart';

//	############################################################################
//	COSTANTI E VARIABILI

var minSupportController = TextEditingController();
var movieRecommendationsController = TextEditingController();
var topFeaturesController = TextEditingController();

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({super.key});

  @override
  State<SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  final _settingsFormKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParams();
  }

  Future<void> _loadParams() async {
    String? data = await BaseClient.instance.getParams().catchError((err) {
      // debugPrint('\n--- ERRORE ---\n$err\n-----\n');
      if (!mounted) return;
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
      setState(() => _isLoading = false);
      return;
    });

    final Map<String, dynamic> paramsMap = toMap(data ?? '{}');
    // debugPrint("$paramsMap");

    try {
      minSupportController.text = paramsMap['minSupport'].toString();
      movieRecommendationsController.text = paramsMap['movieRecommendations']
          .toString();
      topFeaturesController.text = paramsMap['topFeatures'].toString();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  _onSubmit() async {
    if (_settingsFormKey.currentState!.validate()) {
      int minSupport = 0;
      int movieRecommendations = 0;
      int topFeatures = 0;

      try {
        minSupport = int.parse(minSupportController.value.text);
        movieRecommendations = int.parse(
          movieRecommendationsController.value.text,
        );
        topFeatures = int.parse(topFeaturesController.value.text);
      } catch (err) {
        if (!mounted) return;
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
        return;
      }

      _settingsFormKey.currentState!.reset();

      minSupportController.clear();
      movieRecommendationsController.clear();
      topFeaturesController.clear();

      if (!mounted) return;

      BaseClient.instance
          .updateParams(
            minSupport: minSupport,
            movieRecommendations: movieRecommendations,
            topFeatures: topFeatures,
          )
          .then((_) {
            if (!mounted) return;
            if (context.canPop()) context.pop(true);
          })
          .catchError((err) {
            if (!mounted) return;
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
            return;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RecSysAppBar(
        title: 'Impostazioni',
        alignment: Alignment.topLeft,
      ),
      resizeToAvoidBottomInset: false,
      body: _isLoading
          ? const Center(
              child: RecSysLoadingDialog(alertMessage: 'Caricamento...'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                double containerWidth = constraints.maxWidth * 0.5;
                containerWidth = math.max(500, containerWidth);
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
                      child: Form(
                        key: _settingsFormKey,
                        child: Column(
                          spacing: 15.0,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              spacing: 5.0,
                              children: [
                                Text(
                                  "Parametri di configurazione",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge?.copyWith(),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  "Aggiorna qui le impostazioni del sistema di raccomandazione",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            RecSysTextFormField(
                              validator: (value) {
                                switch (Validators.validateInteger(
                                  value as String,
                                )) {
                                  case CheckTypes.emptyValue:
                                    return 'Attenzione! Questo campo è obbligatorio.';
                                  case CheckTypes.notValidRangeNumber:
                                    return 'Attenzione! Inserisci un valore maggiore di 0.';
                                  case CheckTypes.validValue:
                                    return null;
                                  case CheckTypes.notValidPatternEmail:
                                  case CheckTypes.notValidPatternAddress:
                                    return 'Attenzione!';
                                }
                              },
                              controller: minSupportController,
                              tooltip:
                                  "Minimo numero di film a supporto di una feature per poter essere raccomandata.",
                              prefixIcon: Icons.numbers,
                              labelText: 'Supporto minimo',
                              textInputAction: TextInputAction.next,
                            ),
                            RecSysTextFormField(
                              validator: (value) {
                                switch (Validators.validateInteger(
                                  value as String,
                                )) {
                                  case CheckTypes.emptyValue:
                                    return 'Attenzione! Questo campo è obbligatorio.';
                                  case CheckTypes.notValidRangeNumber:
                                    return 'Attenzione! Inserisci un valore maggiore di 0.';
                                  case CheckTypes.validValue:
                                    return null;
                                  case CheckTypes.notValidPatternEmail:
                                  case CheckTypes.notValidPatternAddress:
                                    return 'Attenzione!';
                                }
                              },
                              controller: movieRecommendationsController,
                              tooltip:
                                  "Numero di film raccomandati per ogni feature.",
                              prefixIcon: Icons.numbers,
                              labelText: 'Numero di raccomandazioni',
                              textInputAction: TextInputAction.next,
                            ),
                            RecSysTextFormField(
                              validator: (value) {
                                switch (Validators.validateInteger(
                                  value as String,
                                )) {
                                  case CheckTypes.emptyValue:
                                    return 'Attenzione! Questo campo è obbligatorio.';
                                  case CheckTypes.notValidRangeNumber:
                                    return 'Attenzione! Inserisci un valore maggiore di 0.';
                                  case CheckTypes.validValue:
                                    return null;
                                  case CheckTypes.notValidPatternEmail:
                                  case CheckTypes.notValidPatternAddress:
                                    return 'Attenzione!';
                                }
                              },
                              controller: topFeaturesController,
                              tooltip:
                                  "Numero di feature raccomandate nella schermata principale.",
                              prefixIcon: Icons.numbers,
                              labelText: 'Numero di caroselli',
                              textInputAction: TextInputAction.done,
                            ),
                            Row(
                              spacing: 8.0,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton(
                                    onPressed: _loadParams,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(70),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                    ),
                                    child: Text(
                                      'Ripristina',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.normal,
                                        fontSize: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.fontSize,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(70),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    child: Text(
                                      'Applica',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall?.fontSize,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
