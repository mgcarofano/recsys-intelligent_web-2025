/*

	movie_query_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe MovieQueryRoute rappresenta la schermata che mostra tutti i film
  associati a una specifica query selezionata dall'utente.
  Questa schermata viene raggiunta quando:
  - l'utente clicca "Mostra tutto" in uno dei caroselli della HomeRoute.
  - l'utente clicca il pulsante "Le tue valutazioni"
  nella AppBar della HomeRoute.
  La schermata filtra i film presenti sul server in base alla query
  selezionata, e li mostra in una griglia scrollabile.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/view/widgets/recsys_alert_dialog.dart';
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

class MovieQueryRoute extends StatefulWidget {
  final String queryType;
  final Map<String, dynamic> extras;

  const MovieQueryRoute({
    super.key,
    required this.queryType,
    required this.extras,
  });

  @override
  State<MovieQueryRoute> createState() => _MovieQueryRouteState();
}

class _MovieQueryRouteState extends State<MovieQueryRoute> {
  final List<Movie> _movies = [];
  final List<String> _movieIds = [];

  // Per limitare quanti film vengono scaricati e renderizzati per volta.
  final int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  bool _loadingIds = true;
  bool _loadingMore = false;
  bool _allLoaded = false;

  int _page = 0;

  // Per modificare l'ordinamento dei risultati.
  String _selectedOrder = 'title';

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
    setState(() => _loadingIds = true);

    try {
      String? data;
      if (widget.queryType == 'feature') {
        data = await BaseClient.instance.getMoviesFromFeature(
          featureId: (widget.extras['feature'] as Feature).featureId,
          order: _selectedOrder,
        );
      } else if (widget.queryType == 'ratings') {
        data = await BaseClient.instance.getMoviesFromRatings(
          userId: widget.extras['userId'] as String,
          order: _selectedOrder,
        );
      }

      // debugPrint("$data");
      if (data == null) {
        setState(() {
          _loadingIds = false;
          _allLoaded = true;
        });
        return;
      }

      _movieIds.addAll(toList<String>(data));
      if (_movieIds.isEmpty) {
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

  String _getTitle() {
    if (widget.queryType == 'feature')
      return (widget.extras['feature'] as Feature).name;
    else if (widget.queryType == 'ratings')
      return 'Le tue valutazioni';
    else
      return '';
  }

  Widget _buildMoviesGrid(int numMovies, int columns) {
    return Expanded(
      child: GridView.builder(
        controller: _scrollController,
        physics: _loadingMore
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemCount: numMovies + (_loadingMore ? columns : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 32,
          crossAxisSpacing: 32,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) {
          if (i < _movies.length) {
            final m = _movies[i];

            bool recommended = false;
            if (widget.queryType == 'feature')
              recommended = (widget.extras['recommendedIds'] as List<String>)
                  .contains(m.idMovie);

            return RecSysMovieCard(
              key: ValueKey(m.idMovie),
              movie: m,
              recommended: recommended,
            );
          } else {
            return _buildPlaceholderCard();
          }
        },
      ),
    );
  }

  void _showSortOptions() {
    String tempOrder = _selectedOrder;

    showDialog(
      context: context,
      builder: (context) => RecSysAlertDialog(
        topIcon: Icons.sort,
        alertTitle: 'Ordina i risultati',
        alertContent: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Per titolo'),
                  value: 'title',
                  groupValue: tempOrder,
                  onChanged: (value) => setState(() => tempOrder = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Per valutazione'),
                  value: 'rating',
                  groupValue: tempOrder,
                  onChanged: (value) => setState(() => tempOrder = value!),
                ),
              ],
            );
          },
        ),
        confirmText: "Applica",
        onPressConfirm: () async {
          if (!mounted) return;
          if (context.canPop()) context.pop();
          if (tempOrder != _selectedOrder) {
            setState(() {
              _selectedOrder = tempOrder;
              _movies.clear();
              _movieIds.clear();
              _loadingIds = true;
              _loadingMore = false;
              _allLoaded = false;
              _page = 0;
            });

            await _fetchIdsAndFirstBatch();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RecSysAppBar(title: _getTitle(), alignment: Alignment.topLeft),
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
                      Row(
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: "${_movieIds.length} film trovati",
                              child: Text(
                                "${_movieIds.length} film trovati",
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.sort),
                            onPressed: _showSortOptions,
                            label: Text(
                              "Ordina",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      _buildMoviesGrid(numMovies, columns),
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
