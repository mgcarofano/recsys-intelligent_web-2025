/*

	home_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe HomeRoute rappresenta la schermata principale dell'applicazione,
  dove l'utente può visualizzare le principali raccomandazioni di film che il
  sistema ha generato, in base ai metadati dei film presenti nel database e
  alle preferenze dell'utente stesso. Inoltre, da questa schermata
  l'utente può accedere alle altre funzionalità dell'applicazione, come:
  - la visualizzazione dei dettagli di un film,
  - la visualizzazione delle statistiche dei caroselli,
  - la gestone delle impostazioni dell'applicazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/model/carousel_model.dart';
import 'package:knowledge_recsys/model/feature_model.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';
import 'package:knowledge_recsys/view/widgets/recsys_carousel.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  late Future<List<Carousel>> movieRecommendations;

  @override
  void initState() {
    super.initState();
    movieRecommendations = _getMovieRecommendations();
  }

  Future<List<Carousel>> _getMovieRecommendations() async {
    var data = await BaseClient.instance.getMovieRecommendations().catchError((
      err,
    ) {
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
    if (data == null) return List<Carousel>.empty(growable: true);

    final dataMap = toMap(data);
    // debugPrint("$dataMap");

    return Future.wait(
      dataMap.entries.map((entry) async {
        final featureData = entry.value as Map<String, dynamic>;
        final movieEntries = List<dynamic>.from(featureData["movies"] ?? []);
        // debugPrint("$movieEntries");

        final allIds = movieEntries
            .map((movieEntry) => movieEntry["movie_id"].toString())
            .toList();

        final extras = Map<String, Map<String, dynamic>>.fromEntries(
          movieEntries.map((movieData) {
            return MapEntry(movieData["movie_id"].toString(), {
              "movie_rating": movieData["movie_rating"],
              "seen": movieData["seen"],
              "softmax_prob": movieData["softmax_prob"],
            });
          }),
        );
        // debugPrint("$extras");

        final movies = await fetchMoviesFromIds(allIds, false);

        return Carousel(
          feature: Feature(
            featureId: entry.key,
            category: featureData["category"] as String,
            name: featureData["feature_name"] as String,
            rating: featureData["feature_rating"] as double,
          ),
          allIds: allIds,
          movies: movies,
          nerdStats: extras,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    handleAppBarClick(HomeRouteAction action) async {
      switch (action) {
        case HomeRouteAction.openSettings:
          if (!mounted) return;
          context.push('/settings');
        case HomeRouteAction.logout:
          if (!mounted) return;
          context.go('/login');
      }
    }

    return Scaffold(
      appBar: RecSysAppBar(
        title: 'Knowledge-based Recommender System',
        alignment: Alignment.topLeft,
        actions: [
          IconButton(
            onPressed: () => handleAppBarClick(HomeRouteAction.openSettings),
            icon: const Icon(Icons.settings),
            tooltip: 'Impostazioni',
          ),
          IconButton(
            onPressed: () => handleAppBarClick(HomeRouteAction.logout),
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<List<Carousel>>(
        initialData: List<Carousel>.empty(growable: true),
        future: movieRecommendations,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<Carousel>> carouselSnapshot,
            ) {
              switch (carouselSnapshot.connectionState) {
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

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          spacing: 20.0,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            carouselSnapshot.data!.length,
                            (index) {
                              final carousel = carouselSnapshot.data![index];
                              return RecSysCarousel(
                                carousel: carousel,
                                height: constraints.maxHeight * 0.4,
                                columns: columns,
                              );
                            },
                          ),
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

//  https://stackoverflow.com/questions/68871880/do-not-use-buildcontexts-across-async-gaps
//  https://api.flutter.dev/flutter/material/TextTheme-class.html
//  https://stackoverflow.com/questions/65608681/how-to-create-an-empty-map-in-dart
