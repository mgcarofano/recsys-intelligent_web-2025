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
  final String userId;

  const HomeRoute({super.key, required this.userId});

  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  final List<Carousel> _carousels = [];
  final List<Map<String, dynamic>> _carouselData = [];

  // Per limitare quanti caroselli vengono scaricati e renderizzati per volta.
  final int _pageSize = 3;

  final ScrollController _scrollController = ScrollController();

  bool _loadingIds = true;
  bool _loadingMore = false;
  bool _allLoaded = false;

  int _page = 0;

  @override
  void initState() {
    super.initState();
    // movieRecommendations = _getMovieRecommendations();
    _scrollController.addListener(_onScroll);
    _fetchIdsAndFirstBatch();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchIdsAndFirstBatch() async {
    setState(() => _loadingIds = true);

    try {
      final data = await BaseClient.instance.getMovieRecommendations();

      // debugPrint("$data");
      if (data == null) {
        setState(() {
          _loadingIds = false;
          _allLoaded = true;
        });
        return;
      }

      _carouselData.addAll(toList<Map<String, dynamic>>(data as String));
      // debugPrint("_carouselData: $_carouselData");
      if (_carouselData.isEmpty) {
        setState(() {
          _loadingIds = false;
          _allLoaded = true;
        });
        return;
      }

      setState(() => _loadingIds = false);
      await _loadNextBatch();
      return;
    } catch (err) {
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
      return;
    }
  }

  Future<void> _loadNextBatch() async {
    if (_loadingMore || _allLoaded || _carouselData.isEmpty) return;
    setState(() => _loadingMore = true);

    final start = _page * _pageSize;
    final end = (_page * _pageSize + _pageSize).clamp(0, _carouselData.length);

    if (start >= end) {
      setState(() {
        _loadingMore = false;
        _allLoaded = true;
      });
      return;
    }

    final batchData = _carouselData.sublist(start, end);
    // debugPrint("$batchData");
    // debugPrint("${batchData.length}");

    try {
      List<Carousel> temp = List<Carousel>.empty(growable: true);
      for (final item in batchData) {
        // debugPrint("### START ITERATION ###\n\n");
        // debugPrint("$item");
        final moviesMap = item['movies'] as Map<String, dynamic>;
        // debugPrint("$moviesMap");

        final movies = await fetchMoviesFromData(moviesMap);

        temp.add(
          Carousel(
            feature: Feature(
              featureId: item['feature_id'].toString(),
              category: item["category"].toString(),
              name: item["feature_name"].toString(),
              rating: item["feature_rating"] as double,
            ),
            allIds: moviesMap.keys.toList(),
            movies: movies,
          ),
        );
      }

      // debugPrint("$temp");

      setState(() {
        _carousels.addAll(temp);
        _page++;
        if (end >= _carouselData.length) _allLoaded = true;
        _loadingMore = false;
      });
    } catch (err) {
      // debugPrint('\n--- ERRORE ---\n$err\n-----\n');
      if (!mounted) return;
      setState(() => _loadingMore = false);
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
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _allLoaded) return;
    final threshold = 300.0;
    if (_scrollController.position.pixels + threshold >=
        _scrollController.position.maxScrollExtent) {
      _loadNextBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    handleAppBarClick(HomeRouteAction action) async {
      switch (action) {
        case HomeRouteAction.userRatings:
          if (!mounted) return;
          context.push('/ratings', extra: widget.userId);
        case HomeRouteAction.openSettings:
          if (!mounted) return;
          final shouldReload = await context.push('/settings');
          if (shouldReload == true && mounted)
            setState(() {
              _carousels.clear();
              _carouselData.clear();
              _page = 0;
              _allLoaded = false;
              _fetchIdsAndFirstBatch();
            });
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
          Tooltip(
            message: 'Le tue valutazioni',
            child: TextButton.icon(
              label: Text(
                'Utente n. ${widget.userId}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              onPressed: () => handleAppBarClick(HomeRouteAction.userRatings),
              icon: const Icon(Icons.account_circle),
              iconAlignment: IconAlignment.end,
            ),
          ),
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
      body: _loadingIds
          ? const RecSysLoadingDialog(alertMessage: 'Caricamento...')
          : RefreshIndicator(
              onRefresh: () async {
                _carousels.clear();
                _page = 0;
                _allLoaded = false;
                await _fetchIdsAndFirstBatch();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        spacing: 20.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_carousels.length, (index) {
                          final carousel = _carousels[index];
                          return RecSysCarousel(
                            carousel: carousel,
                            height: constraints.maxHeight * 0.4,
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
      // body: FutureBuilder<List<Carousel>>(
      //   initialData: List<Carousel>.empty(growable: true),
      //   future: movieRecommendations,
      //   builder:
      //       (
      //         BuildContext context,
      //         AsyncSnapshot<List<Carousel>> carouselSnapshot,
      //       ) {
      //         switch (carouselSnapshot.connectionState) {
      //           case ConnectionState.none:
      //           case ConnectionState.waiting:
      //           case ConnectionState.active:
      //             return RecSysLoadingDialog(alertMessage: 'Caricamento...');
      //           case ConnectionState.done:
      //             return LayoutBuilder(
      //               builder: (context, constraints) => SingleChildScrollView(
      //                 padding: const EdgeInsets.all(20.0),
      //                 child: Column(
      //                   spacing: 20.0,
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: List.generate(carouselSnapshot.data!.length, (
      //                     index,
      //                   ) {
      //                     final carousel = carouselSnapshot.data![index];
      //                     return RecSysCarousel(
      //                       carousel: carousel,
      //                       height: constraints.maxHeight * 0.4,
      //                     );
      //                   }),
      //                 ),
      //               ),
      //             );
      //         }
      //       },
      // ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI

//  https://stackoverflow.com/questions/68871880/do-not-use-buildcontexts-across-async-gaps
//  https://api.flutter.dev/flutter/material/TextTheme-class.html
//  https://stackoverflow.com/questions/65608681/how-to-create-an-empty-map-in-dart
