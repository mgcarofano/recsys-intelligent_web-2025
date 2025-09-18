/*

	home_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe HomeRoute rappresenta la schermata principale dell'applicazione,
  dove l'utente può visualizzare le principali raccomandazioni di film e serie
  TV che il sistema ha generato, in base ai metadati dei film presenti nel
  database e alle preferenze dell'utente stesso. Inoltre, da questa schermata
  l'utente può accedere alle altre funzionalità dell'applicazione, come la
  visualizzazione dei dettagli di un film, la gestione del profilo utente e le
  impostazioni dell'applicazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/theme.dart';
import 'package:knowledge_recsys/view/widgets/recsys_alert_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_movie_card.dart';

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
  late Future<List<Movie>> movieRecommendations;
  final Set<Movie> selectedMovies = {};

  @override
  void initState() {
    super.initState();
    movieRecommendations = _getMovieRecommendations();
  }

  Future<List<Movie>> _getMovieRecommendations() async {
    List<Movie> list = List<Movie>.empty(growable: true);
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
    if (data == null) return List<Movie>.empty(growable: true);

    for (String id in toList(data as String) as List<String>) {
      String? movieInfo = await BaseClient.instance
          .getMovieInfo(idMovie: id)
          .catchError((_) => null);

      // debugPrint("$id, ${movieInfo.runtimeType.toString()}, $movieInfo");

      Map<String, dynamic> movieMap = toMap(movieInfo ?? '{}');

      Movie m = Movie(
        idMovie: id,
        title: movieMap['title'][0] as String,
        description: movieMap['description'][0] as String,
        actors: List<String>.from(movieMap['actors'] ?? []),
        composers: List<String>.from(movieMap['composers'] ?? []),
        directors: List<String>.from(movieMap['directors'] ?? []),
        genres: List<String>.from(movieMap['genres'] ?? []),
        producers: List<String>.from(movieMap['producers'] ?? []),
        productionCompanies: List<String>.from(
          movieMap['production_companies'] ?? [],
        ),
        subjects: List<String>.from(movieMap['subjects'] ?? []),
        writers: List<String>.from(movieMap['writers'] ?? []),
      );

      if (!list.any((movie) => movie.idMovie == id)) {
        list.add(m);
      }
    }

    // debugPrint(list.toString());

    return list;
  }

  Future<void> _refreshHomePage() async {
    if (selectedMovies.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Seleziona almeno un film'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      return;
    }

    final selectedIds = selectedMovies
        .map((m) => m.idMovie.toString())
        .toList();
    final selectedTitles = selectedMovies.map((m) => m.title).join('\n');

    Future<void> confirmAction() async {
      try {
        // debugPrint(selectedMovieIds.toString());
        if (!mounted) return;
        context.pop();

        await BaseClient.instance
            .postUserPreferences(idMovies: selectedIds)
            .catchError((err) {
              debugPrint('\n--- ERRORE ---\n$err\n-----\n');
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
            });

        // Ricarica i nuovi dati dopo la POST
        setState(() {
          selectedMovies.clear();
          movieRecommendations = _getMovieRecommendations().then((val) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Preferenze aggiornate con successo!'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.successContainer,
                  ),
                );
            }
            return val;
          });
        });
      } catch (err) {
        if (!mounted) return;
        context.pop();
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
      }
    }

    showDialog(
      context: context,
      builder: (context) => RecSysAlertDialog(
        topIcon: Icons.help_outline_rounded,
        alertTitle: 'Aggiorna preferenze',
        alertMessage: "Confermi la tua selezione?\n$selectedTitles",
        onPressConfirm: confirmAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int totalCards = 15;
    const int maxColumns = 5;

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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshHomePage,
        tooltip: 'Aggiorna',
        child: const Icon(Icons.cloud_sync),
      ),
      body: FutureBuilder<List<Movie>>(
        initialData: List<Movie>.empty(growable: true),
        future: movieRecommendations,
        builder: (BuildContext context, AsyncSnapshot<List<Movie>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return RecSysLoadingDialog(alertMessage: 'Caricamento...');
            case ConnectionState.done:
              // return Placeholder();
              return LayoutBuilder(
                builder: (context, constraints) {
                  final double cardWidth = 350;
                  final int columns = (constraints.maxWidth / cardWidth)
                      .floor()
                      .clamp(1, maxColumns);

                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      spacing: 20.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Seleziona i film e poi premi il tasto in basso per aggiornare le tue preferenze.",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              spacing: 10.0,
                              children: [
                                Text(
                                  'Film selezionati: ${selectedMovies.length}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      if (selectedMovies.length ==
                                          snapshot.data!.length)
                                        selectedMovies.clear();
                                      else
                                        selectedMovies
                                          ..clear()
                                          ..addAll(snapshot.data!);
                                    });
                                  },
                                  icon: Icon(
                                    selectedMovies.length ==
                                            snapshot.data!.length
                                        ? Icons.clear_all
                                        : Icons.select_all,
                                  ),
                                  label: Text(
                                    selectedMovies.length ==
                                            snapshot.data!.length
                                        ? 'Deseleziona tutti'
                                        : 'Seleziona tutti',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: GridView.builder(
                            itemCount: min(snapshot.data!.length, totalCards),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 32,
                                  crossAxisSpacing: 32,
                                  childAspectRatio: 5 / 5,
                                ),
                            itemBuilder: (context, index) {
                              final m = snapshot.data![index];
                              final isSelected = selectedMovies.contains(m);

                              return RecSysMovieCard(
                                movie: m,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected)
                                      selectedMovies.remove(m);
                                    else
                                      selectedMovies.add(m);
                                  });
                                },
                              );
                            },
                          ),
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

//  https://stackoverflow.com/questions/68871880/do-not-use-buildcontexts-across-async-gaps
//  https://api.flutter.dev/flutter/material/TextTheme-class.html
