/*

	feature_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe FeatureRoute rappresenta la schermata che mostra tutti i film
  associati a una specifica feature selezionata dall'utente.
  Questa schermata viene raggiunta quando l'utente clicca su una feature
  in uno dei caroselli della schermata principale (HomeRoute).
  La FeatureRoute visualizza una lista di film che condividono la stessa
  caratteristica, permettendo all'utente di esplorare e scoprire nuovi
  contenuti basati sui suoi interessi.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
  final List<Movie> _movies = [];
  final List<String> _movieIds = [];

  final ScrollController _scrollController = ScrollController();

  bool _loadingIds = true;
  bool _loadingMore = false;
  bool _allLoaded = false;

  int _page = 0;

  // Per limitare quanti film vengono scaricati e renderizzati per volta.
  final int _pageSize = maxColumns;

  @override
  void initState() {
    super.initState();
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
    try {
      var data = await BaseClient.instance.getMoviesFromFeature(
        featureId: widget.feature.featureId,
        order: true,
      );
      // debugPrint("$data");
      if (data == null) {
        setState(() {
          _loadingIds = false;
          _allLoaded = true;
        });
        return;
      }

      _movieIds.addAll(toList(data) as List<String>);
      if (_movieIds.isEmpty) {
        setState(() => _loadingIds = false);
        return;
      }

      setState(() => _loadingIds = false);
      await _loadNextBatch();
      return;
    } catch (err) {
      // debugPrint('\n--- ERRORE ---\n$err\n-----\n');
      if (!mounted) return;
      setState(() => _loadingIds = false);
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
    if (_loadingMore || _allLoaded || _movieIds.isEmpty) return;
    setState(() => _loadingMore = true);

    final start = _page * _pageSize;
    final end = (_page * _pageSize + _pageSize).clamp(0, _movieIds.length);

    if (start >= end) {
      setState(() {
        _loadingMore = false;
        _allLoaded = true;
      });
      return;
    }

    final batchIds = _movieIds.sublist(start, end);

    try {
      final batchMovies = await fetchMoviesFromIds(batchIds);

      setState(() {
        _movies.addAll(batchMovies);
        _page++;
        if (end >= _movieIds.length) _allLoaded = true;
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
    final threshold =
        300.0; // quando mancano meno di 300px dal fondo, carica altro
    if (_scrollController.position.pixels + threshold >=
        _scrollController.position.maxScrollExtent) {
      _loadNextBatch();
    }
  }

  Widget _buildPlaceholderCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.grey.shade400,
                  ),
                  Container(
                    height: 14,
                    width: 120,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RecSysAppBar(
        title: widget.feature.name,
        alignment: Alignment.topLeft,
      ),
      resizeToAvoidBottomInset: false,
      body: _loadingIds
          ? const RecSysLoadingDialog(alertMessage: 'Caricamento...')
          : LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = 350;
                final int columns = (constraints.maxWidth / cardWidth)
                    .floor()
                    .clamp(1, maxColumns);
                final numMovies = _movies.length;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    spacing: 20.0,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_movieIds.length} film trovati",
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: _loadingMore
                              ? const NeverScrollableScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(),
                          itemCount: numMovies + (_loadingMore ? columns : 0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 32,
                                crossAxisSpacing: 32,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, i) {
                            if (i < _movies.length) {
                              final m = _movies[i];
                              return RecSysMovieCard(
                                key: ValueKey(m.idMovie),
                                feature: widget.feature,
                                movie: m,
                                recommended:
                                    widget.recommendedIds?.contains(
                                      m.idMovie,
                                    ) ??
                                    false,
                              );
                            } else {
                              return _buildPlaceholderCard();
                            }
                          },
                        ),
                      ),
                      if (_loadingMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(child: Text('Caricamento...')),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
