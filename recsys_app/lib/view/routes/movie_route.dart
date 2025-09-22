/*

	movie_route.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe MovieRoute rappresenta la schermata dei dettagli di un film, dove
  l'utente può visualizzare le informazioni principali (e.g. titolo,
  descrizione, anno di uscita, ...), una breve spiegazione del motivo per cui
  il film è stato raccomandato e altri parametri più specifici propri del
  sistema di raccomandazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/cache/poster_cache.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/view/widgets/recsys_alert_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_app_bar.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class MovieRoute extends StatefulWidget {
  final Movie movie;

  const MovieRoute({super.key, required this.movie});

  @override
  State<MovieRoute> createState() => _MovieRouteState();
}

class _MovieRouteState extends State<MovieRoute> {
  Uint8List? _moviePosterBytes;
  bool _isPosterLoading = true;

  @override
  void initState() {
    super.initState();
    _initRawMoviePoster();
  }

  Future<void> _initRawMoviePoster() async {
    //  ########################################################################
    //  Verifica se il poster già esiste nella memoria cache.

    var data = PosterCache.get(widget.movie.idMovie);

    if (data != null) {
      setState(() {
        _moviePosterBytes = Uint8List.fromList(data);
        _isPosterLoading = false;
      });
      return;
    }

    //  ########################################################################
    //  Se non è stato trovato alcun poster nella cache.

    setState(() {
      _moviePosterBytes = null;
      _isPosterLoading = false;
    });

    return;
  }

  Widget _buildInfo(IconData icon, String title, Widget info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.0,
      children: [
        Row(
          spacing: 10.0,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.tertiary, size: 24),
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
        info,
        Divider(),
      ],
    );
  }

  Widget _buildList(List<String> items) {
    int counter = 0;
    final text = items
        .map((item) {
          counter += 1;
          return "${counter == 1 ? "" : "• "}$item";
        })
        .join(" ");

    return Text(text, style: Theme.of(context).textTheme.bodyLarge);
  }

  Widget _buildChips() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 10,
          runSpacing: 7,
          children: widget.movie.subjects!.map((subject) {
            return Chip(
              label: Text(
                subject,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black),
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> handleAppBarClick(MovieRouteAction action) async {
    switch (action) {
      case MovieRouteAction.showNerdStats:
        showDialog(
          context: context,
          builder: (context) => RecSysAlertDialog(
            topIcon: Icons.bar_chart,
            alertTitle: 'Statistiche per nerd',
            alertMessage: "...",
            cancelText: "Ok",
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: RecSysAppBar(
        title: "Informazioni",
        alignment: Alignment.topLeft,
        actions: [
          IconButton(
            onPressed: () => handleAppBarClick(MovieRouteAction.showNerdStats),
            icon: const Icon(Icons.bar_chart),
            tooltip: "Statistiche per nerd",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (_isPosterLoading)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        if (_moviePosterBytes == null)
                          return const Placeholder();
                        else {
                          return Image.memory(
                            _moviePosterBytes!,
                            fit: BoxFit.cover,
                          );
                        }
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.movie.title ??
                            "Movie n. ${widget.movie.idMovie}",
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20.0,
                children: [
                  if (widget.movie.description != null &&
                      widget.movie.description!.isNotEmpty)
                    _buildInfo(
                      Icons.description_outlined,
                      "Description",
                      Text(
                        widget.movie.description ?? "",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (widget.movie.genres != null &&
                      widget.movie.genres!.isNotEmpty)
                    _buildInfo(
                      Icons.theater_comedy_outlined,
                      "Genres",
                      _buildList(widget.movie.genres!),
                    ),
                  if (widget.movie.actors != null &&
                      widget.movie.actors!.isNotEmpty)
                    _buildInfo(
                      Icons.recent_actors_outlined,
                      "Actors",
                      _buildList(widget.movie.actors!),
                    ),
                  if (widget.movie.directors != null &&
                      widget.movie.directors!.isNotEmpty)
                    _buildInfo(
                      Icons.movie_outlined,
                      "Directors",
                      _buildList(widget.movie.directors!),
                    ),
                  if (widget.movie.writers != null &&
                      widget.movie.writers!.isNotEmpty)
                    _buildInfo(
                      Icons.edit_outlined,
                      "Writers",
                      _buildList(widget.movie.writers!),
                    ),
                  if (widget.movie.composers != null &&
                      widget.movie.composers!.isNotEmpty)
                    _buildInfo(
                      Icons.music_note_outlined,
                      "Composers",
                      _buildList(widget.movie.composers!),
                    ),
                  if (widget.movie.subjects != null &&
                      widget.movie.subjects!.isNotEmpty)
                    _buildInfo(
                      Icons.category_outlined,
                      "Subjects",
                      _buildChips(),
                    ),
                  if (widget.movie.producers != null &&
                      widget.movie.producers!.isNotEmpty)
                    _buildInfo(
                      Icons.paid_outlined,
                      "Producers",
                      _buildList(widget.movie.producers!),
                    ),
                  if (widget.movie.productionCompanies != null &&
                      widget.movie.productionCompanies!.isNotEmpty)
                    _buildInfo(
                      Icons.theaters_outlined,
                      "Production companies",
                      _buildList(widget.movie.productionCompanies!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
