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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';
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
  final Set<String> selectedMovieIds = {};
  var isLoading = false;

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

    if (data == null) return List<Movie>.empty(growable: true);

    for (String id in toList(data as String) as List<String>) {
      Movie m = Movie(
        idMovie: id,
        title: await BaseClient.instance
            .getMovieTitle(idMovie: id)
            .catchError((_) => null),
        description: await BaseClient.instance
            .getMovieDescription(idMovie: id)
            .catchError((_) => null),
        subjects: await BaseClient.instance
            .getMovieSubjects(idMovie: id)
            .catchError((_) => null),
      );

      if (!list.any((movie) => movie.idMovie == id)) {
        list.add(m);
      }
    }

    return list;
  }

  Future<void> _refreshHomePage() async {
    // setState(() {
    //   isLoading = true;
    // });

    // try {
    //   // Attendi il risultato della Future e decodifica la stringa JSON
    //   // in una lista di stringhe.
    //   final String rawList = await movieRecommendationsResponse;
    //   final List<String> idMovies = toList(rawList) as List<String>;

    //   final response = await BaseClient.instance
    //       .postUserPreferences(idMovies: idMovies)
    //       .catchError((err) {
    //         debugPrint('\n--- ERRORE ---\n$err\n-----\n');
    //         if (!mounted) return;
    //         ScaffoldMessenger.of(context)
    //           ..hideCurrentSnackBar()
    //           ..showSnackBar(
    //             SnackBar(
    //               behavior: SnackBarBehavior.floating,
    //               content: Text(err.toString()),
    //               duration: const Duration(seconds: 3),
    //               backgroundColor: Theme.of(context).colorScheme.error,
    //             ),
    //           );
    //       });

    //   if (response == null) {
    //     if (!mounted) return;
    //     ScaffoldMessenger.of(context)
    //       ..hideCurrentSnackBar()
    //       ..showSnackBar(
    //         SnackBar(
    //           behavior: SnackBarBehavior.floating,
    //           content: Text('Errore durante la ricezione dei dati.'),
    //           duration: const Duration(seconds: 3),
    //           backgroundColor: Theme.of(context).colorScheme.error,
    //         ),
    //       );
    //     return;
    //   }

    //   // Ricarica i nuovi dati dopo la POST
    //   movieRecommendationsResponse = _getMovieRecommendationsRawList();

    //   setState(() {
    //     isLoading = false;
    //   });

    //   if (!mounted) return;
    //   ScaffoldMessenger.of(context)
    //     ..hideCurrentSnackBar()
    //     ..showSnackBar(
    //       SnackBar(
    //         behavior: SnackBarBehavior.floating,
    //         content: Text('Preferenze aggiornate con successo!'),
    //         duration: const Duration(seconds: 3),
    //         backgroundColor: Theme.of(context).colorScheme.tertiary,
    //       ),
    //     );
    // } catch (err) {
    //   setState(() {
    //     isLoading = false;
    //   });

    //   ScaffoldMessenger.of(context)
    //     ..hideCurrentSnackBar()
    //     ..showSnackBar(
    //       SnackBar(
    //         behavior: SnackBarBehavior.floating,
    //         content: Text(err.toString()),
    //         duration: const Duration(seconds: 3),
    //         backgroundColor: Theme.of(context).colorScheme.error,
    //       ),
    //     );
    // }
  }

  // void _toggleSelection(String movieId) {
  //   setState(() {
  //     if (_selectedMovieIds.contains(movieId)) {
  //       _selectedMovieIds.remove(movieId);
  //     } else {
  //       _selectedMovieIds.add(movieId);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // final card = RecSysMovieCard(
    //   movie: Movie(
    //     idMovie: '59315',
    //     title: 'Iron Man',
    //     description:
    //         "Iron Man è un film del 2008 diretto da Jon Favreau. Basato sull'omonimo personaggio dei fumetti della Marvel Comics Iron Man, interpretato da Robert Downey Jr., è il primo film del Marvel Cinematic Universe, della cosiddetta \"Fase Uno\" e della \"Saga dell'infinito\".",
    //     subjects: [
    //       'Azione',
    //       'Avventura',
    //       'Stati Uniti',
    //       'Supereroi',
    //       'Los Angeles',
    //       '2008',
    //     ],
    //   ),
    // );

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
        child: const Icon(Icons.refresh_rounded),
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
              return LayoutBuilder(
                builder: (context, constraints) {
                  final double cardWidth = 350;
                  final int columns = (constraints.maxWidth / cardWidth)
                      .floor()
                      .clamp(1, maxColumns);

                  return GridView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: totalCards,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 32,
                      crossAxisSpacing: 32,
                      childAspectRatio: 5 / 4,
                    ),
                    itemBuilder: (context, index) => const Placeholder(),
                    // RecSysMovieCard(movie: snapshot.data![index]),
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
