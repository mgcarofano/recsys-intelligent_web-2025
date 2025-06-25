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
  late Future<String> movieRecommendationsResponse;
  var isLoading = false;

  Future<String> _getMovieRecommendationsRawList() async {
    var data = await BaseClient.instance.getMovieRecommendations().catchError((
      err,
    ) {
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
    });

    return data ?? '[]';
  }

  Future<void> _refreshHomePage() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Attendi il risultato della Future e decodifica la stringa JSON in una lista di stringhe
      final String rawList = await movieRecommendationsResponse;
      final List<String> idMovies = toList(rawList) as List<String>;

      final response = await BaseClient.instance
          .postUserPreferences(idMovies: idMovies)
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

      if (response == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Errore durante la ricezione dei dati.'),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        return;
      }

      // Ricarica i nuovi dati dopo la POST
      movieRecommendationsResponse = _getMovieRecommendationsRawList();

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Preferenze aggiornate con successo!'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
    } catch (err) {
      setState(() {
        isLoading = false;
      });

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

  @override
  void initState() {
    super.initState();
    movieRecommendationsResponse = _getMovieRecommendationsRawList();
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshHomePage,
        tooltip: 'Aggiorna',
        child: const Icon(Icons.refresh_rounded),
      ),
      body: FutureBuilder(
        initialData: '[]',
        future: movieRecommendationsResponse,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return RecSysLoadingDialog(alertMessage: 'Caricamento...');
            case ConnectionState.done:
              // return Center(child: Text(snapshot.data ?? '[]'));
              return Center(
                child: RecSysMovieCard(
                  idMovie: '59315',
                  title: 'Iron Man',
                  description:
                      "Iron Man è un film del 2008 diretto da Jon Favreau. Basato sull'omonimo personaggio dei fumetti della Marvel Comics Iron Man, interpretato da Robert Downey Jr., è il primo film del Marvel Cinematic Universe, della cosiddetta \"Fase Uno\" e della \"Saga dell'infinito\".",
                  subjects: [
                    'Azione',
                    'Avventura',
                    'Supereroi',
                    '2008',
                    'Stati Uniti',
                    'Los Angeles',
                  ],
                ),
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
