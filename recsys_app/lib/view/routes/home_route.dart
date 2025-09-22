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
import 'package:knowledge_recsys/model/carousel_model.dart';
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

const int maxColumns = 5;

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
  // final Set<Movie> selectedMovies = {};
  final expanded = List.filled(3, false);

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

    // List<Carousel> list = [];
    final dataMap = toMap(data);
    // debugPrint("$dataMap");

    Future<List<Movie>> fetchMoviesFromIds(List<String> ids) async {
      final ret = ids.toSet().map((id) async {
        String? movieInfo = await BaseClient.instance
            .getMovieInfo(idMovie: id)
            .catchError((_) => null);

        Map<String, dynamic> movieMap = toMap(movieInfo ?? '{}');

        final t = safeFirst(movieMap['title']);
        final d = safeFirst(movieMap['description']);

        return Movie(
          idMovie: id,
          title: t ?? "",
          description: d ?? "",
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
      }).toList();

      return (await Future.wait(ret)).whereType<Movie>().toList();
    }

    return Future.wait(
      dataMap.entries.expand((entry) {
        final category = entry.key;

        final featuresMap = entry.value as Map<String, dynamic>;
        // debugPrint("$featuresMap");

        return featuresMap.entries.map((featureData) async {
          final featureName = featureData.key;
          final ids = List<String>.from(featureData.value ?? []);
          // debugPrint("$featureName, $ids");

          final movies = await fetchMoviesFromIds(ids);

          return Carousel(
            category: category,
            featureName: featureName,
            movies: movies,
          );
        });
      }),
    );

    // Future<List<Movie>> fetchMoviesFromIds(List<String> ids) async {
    //   List<Movie> ret = [];

    //   for (var id in ids) {
    //     if (ret.any((movie) => movie.idMovie == id)) break;

    //     String? movieInfo = await BaseClient.instance
    //         .getMovieInfo(idMovie: id)
    //         .catchError((_) => null);

    //     Map<String, dynamic> movieMap = toMap(movieInfo ?? '{}');

    //     final t = safeFirst(movieMap['title']);
    //     final d = safeFirst(movieMap['description']);

    //     Movie m = Movie(
    //       idMovie: id,
    //       title: t ?? "",
    //       description: d ?? "",
    //       actors: List<String>.from(movieMap['actors'] ?? []),
    //       composers: List<String>.from(movieMap['composers'] ?? []),
    //       directors: List<String>.from(movieMap['directors'] ?? []),
    //       genres: List<String>.from(movieMap['genres'] ?? []),
    //       producers: List<String>.from(movieMap['producers'] ?? []),
    //       productionCompanies: List<String>.from(
    //         movieMap['production_companies'] ?? [],
    //       ),
    //       subjects: List<String>.from(movieMap['subjects'] ?? []),
    //       writers: List<String>.from(movieMap['writers'] ?? []),
    //     );

    //     ret.add(m);
    //   }

    //   return ret;
    // }

    // for (final entry in map.entries) {
    //   final category = entry.key;
    //   final features = Map<String, dynamic>.from(entry.value);

    //   for (final featureEntry in features.entries) {
    //     final featureName = featureEntry.key;
    //     final ids = List<String>.from(featureEntry.value);

    //     // debugPrint("${featureName.runtimeType.toString()}, $featureName");
    //     // debugPrint("${ids.runtimeType.toString()}, $ids, ${ids.length}");

    //     final movies = await fetchMoviesFromIds(ids);

    //     list.add(
    //       Carousel(
    //         category: category,
    //         featureName: featureName,
    //         movies: movies,
    //       ),
    //     );
    //   }

    //   // debugPrint(list.toString());
    // }

    // return list;
  }

  String _buildCategoryTitle({
    required String category,
    required List<String> params,
  }) {
    switch (category) {
      case "actors":
        return "Ti è piaciuto '${params[0]}'? Scopri altri ${params[1]} film in cui è protagonista";
      case "composers":
        return "Hai amato la colonna sonora di '${params[0]}'? Lasciati guidare da questi altri ${params[1]} capolavori";
      case "directors":
        return "${params[1]} film diretti dalla mano visionaria di '${params[0]}'";
      case "genres":
        return "Scopri altri ${params[1]} titoli '${params[0]}'";
      case "producers":
        return "Se '${params[0]}' ti ha convinto, lasciati stupire dalle sue ${params[1]} produzioni";
      case "production_companies":
        return "Per te che ami '${params[0]}', ecco altri ${params[1]} film che non puoi perdere";
      case "subjects":
        return "Se '${params[0]}' ti ha appassionato, ecco ${params[1]} nuovi film";
      case "writers":
        return "Hai apprezzato la sceneggiatura di '${params[0]}'? Scopri queste altre ${params[1]} storie";
      default:
        return "${params[1]} film";
    }
  }

  Widget _buildCarouselHeader(Carousel c, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _buildCategoryTitle(
              category: c.category,
              params: [c.featureName, c.movies.length.toString()],
            ),
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (c.movies.length > maxColumns)
          TextButton.icon(
            onPressed: () => setState(() {
              expanded[index] = !expanded[index];
            }),
            icon: Icon(expanded[index] ? Icons.expand_less : Icons.expand_more),
            label: Text(
              expanded[index] ? "Mostra meno" : "Mostra tutto",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselMoviesList(
    Carousel c,
    bool expanded,
    double h,
    int columns,
  ) {
    if (!expanded)
      return SizedBox(
        height: h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: min(c.movies.length, maxColumns),
          separatorBuilder: (_, __) => const SizedBox(width: 32),
          itemBuilder: (context, i) => RecSysMovieCard(movie: c.movies[i]),
        ),
      );
    else
      return GridView.builder(
        itemCount: c.movies.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 32,
          crossAxisSpacing: 32,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) => RecSysMovieCard(movie: c.movies[i]),
      );
  }

  // Future<void> _refreshHomePage() async {
  //   if (selectedMovies.isEmpty) {
  //     ScaffoldMessenger.of(context)
  //       ..hideCurrentSnackBar()
  //       ..showSnackBar(
  //         SnackBar(
  //           behavior: SnackBarBehavior.floating,
  //           content: Text('Seleziona almeno un film'),
  //           duration: const Duration(seconds: 3),
  //           backgroundColor: Theme.of(context).colorScheme.error,
  //         ),
  //       );
  //     return;
  //   }

  //   final selectedIds = selectedMovies
  //       .map((m) => m.idMovie.toString())
  //       .toList();
  //   final selectedTitles = selectedMovies.map((m) => m.title).join('\n');

  //   Future<void> confirmAction() async {
  //     try {
  //       // debugPrint(selectedMovieIds.toString());
  //       if (!mounted) return;
  //       context.pop();

  //       await BaseClient.instance
  //           .postUserPreferences(idMovies: selectedIds)
  //           .catchError((err) {
  //             debugPrint('\n--- ERRORE ---\n$err\n-----\n');
  //             if (!mounted) return;
  //             ScaffoldMessenger.of(context)
  //               ..hideCurrentSnackBar()
  //               ..showSnackBar(
  //                 SnackBar(
  //                   behavior: SnackBarBehavior.floating,
  //                   content: Text(err.toString()),
  //                   duration: const Duration(seconds: 3),
  //                   backgroundColor: Theme.of(context).colorScheme.error,
  //                 ),
  //               );
  //           });

  //       // Ricarica i nuovi dati dopo la POST
  //       setState(() {
  //         selectedMovies.clear();
  //         movieRecommendations = _getMovieRecommendations().then((val) {
  //           if (mounted) {
  //             ScaffoldMessenger.of(context)
  //               ..hideCurrentSnackBar()
  //               ..showSnackBar(
  //                 SnackBar(
  //                   behavior: SnackBarBehavior.floating,
  //                   content: Text('Preferenze aggiornate con successo!'),
  //                   duration: const Duration(seconds: 3),
  //                   backgroundColor: Theme.of(
  //                     context,
  //                   ).colorScheme.successContainer,
  //                 ),
  //               );
  //           }
  //           return val;
  //         });
  //       });
  //     } catch (err) {
  //       if (!mounted) return;
  //       context.pop();
  //       ScaffoldMessenger.of(context)
  //         ..hideCurrentSnackBar()
  //         ..showSnackBar(
  //           SnackBar(
  //             behavior: SnackBarBehavior.floating,
  //             content: Text(err.toString()),
  //             duration: const Duration(seconds: 3),
  //             backgroundColor: Theme.of(context).colorScheme.error,
  //           ),
  //         );
  //     }
  //   }

  //   showDialog(
  //     context: context,
  //     builder: (context) => RecSysAlertDialog(
  //       topIcon: Icons.help_outline_rounded,
  //       alertTitle: 'Aggiorna preferenze',
  //       alertMessage: "Confermi la tua selezione?\n$selectedTitles",
  //       onPressConfirm: confirmAction,
  //     ),
  //   );
  // }

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
          // IconButton(
          //   onPressed: () => handleAppBarClick(HomeRouteAction.openSettings),
          //   icon: const Icon(Icons.settings),
          //   tooltip: 'Impostazioni',
          // ),
          IconButton(
            onPressed: () => handleAppBarClick(HomeRouteAction.logout),
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _refreshHomePage,
      //   tooltip: 'Aggiorna',
      //   child: const Icon(Icons.cloud_sync),
      // ),
      body: FutureBuilder<List<Carousel>>(
        initialData: List<Carousel>.empty(growable: true),
        future: movieRecommendations,
        builder:
            (BuildContext context, AsyncSnapshot<List<Carousel>> snapshot) {
              switch (snapshot.connectionState) {
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
                          children: List.generate(snapshot.data!.length, (
                            index,
                          ) {
                            final carousel = snapshot.data![index];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10.0,
                              children: [
                                _buildCarouselHeader(carousel, index),
                                _buildCarouselMoviesList(
                                  carousel,
                                  expanded[index],
                                  constraints.maxHeight * 0.4,
                                  columns,
                                ),
                                const Divider(),
                              ],
                            );
                          }),
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
