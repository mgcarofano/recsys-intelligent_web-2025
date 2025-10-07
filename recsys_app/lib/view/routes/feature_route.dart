/*

	feature_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe FeatureRoute rappresenta la schermata che mostra tutti i film associati a una specifica feature selezionata dall'utente. Questa schermata viene raggiunta quando l'utente clicca su una feature in uno dei caroselli della schermata principale (HomeRoute). La FeatureRoute visualizza una lista di film che condividono la stessa caratteristica, permettendo all'utente di esplorare e scoprire nuovi contenuti basati sui suoi interessi.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/model/feature_model.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_movie_card.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class FeatureRoute extends StatefulWidget {
  final Feature feature;
  final List<String>? recommendedIds;

  const FeatureRoute({super.key, required this.feature, this.recommendedIds});

  @override
  State<FeatureRoute> createState() => _FeatureRouteState();
}

class _FeatureRouteState extends State<FeatureRoute> {
  late Future<List<Movie>> allMovies;

  @override
  void initState() {
    super.initState();
    allMovies = _getAllMovies();
  }

  Future<List<Movie>> _getAllMovies() async {
    var data = await BaseClient.instance
        .getMoviesFromFeature(featureId: widget.feature.featureId)
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

    // debugPrint("$data");
    if (data == null) return List<Movie>.empty(growable: true);

    return await fetchMoviesFromIds(toList(data) as List<String>, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RecSysAppBar(
        title: widget.feature.name,
        alignment: Alignment.topLeft,
      ),
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<List<Movie>>(
        initialData: List<Movie>.empty(growable: true),
        future: allMovies,
        builder:
            (BuildContext context, AsyncSnapshot<List<Movie>> moviesSnapshot) {
              switch (moviesSnapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                case ConnectionState.active:
                  return RecSysLoadingDialog(alertMessage: 'Caricamento...');
                case ConnectionState.done:
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double cardWidth = 350;
                      final int columns = (constraints.maxWidth / cardWidth)
                          .floor()
                          .clamp(1, maxColumns);
                      final numMovies = moviesSnapshot.data!.length;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          spacing: 20.0,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$numMovies film trovati",
                              style: Theme.of(context).textTheme.headlineMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            GridView.builder(
                              itemCount: numMovies,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 32,
                                    crossAxisSpacing: 32,
                                    childAspectRatio: 1,
                                  ),
                              itemBuilder: (context, i) {
                                final m = moviesSnapshot.data![i];

                                return RecSysMovieCard(
                                  feature: widget.feature,
                                  movie: m,
                                  recommended:
                                      widget.recommendedIds?.contains(
                                        m.idMovie,
                                      ) ??
                                      false,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
              }
            },
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
