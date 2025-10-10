/*

	recsys_movie_card.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe RecSysMovieCard rappresenta una card che visualizza le informazioni
  su un film raccomandato dal sistema, inclusi il titolo, la descrizione e
  alcuni features associate. La card include anche la copertina del film, che
  viene scaricata dal server se non è già presente nella cache locale.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_recsys/cache/poster_cache.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/view/widgets/recsys_alert_dialog.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class RecSysMovieCard extends StatefulWidget {
  final Movie movie;

  const RecSysMovieCard({super.key, required this.movie});

  @override
  State<RecSysMovieCard> createState() => _RecSysMovieCardState();
}

class _RecSysMovieCardState extends State<RecSysMovieCard> {
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
        _moviePosterBytes = Uint8List.fromList(data!);
        _isPosterLoading = false;
      });
      return;
    }

    //  ########################################################################
    //  Se non è già disponibile, scarica il poster dal server.

    data = await BaseClient.instance
        .downloadMoviePoster(idMovie: widget.movie.idMovie)
        .catchError((err) {
          // debugPrint('\n--- ERRORE ---\n$err\n-----\n');
        });

    if (data != null) {
      setState(() {
        _moviePosterBytes = Uint8List.fromList(data!);
        PosterCache.set(widget.movie.idMovie, _moviePosterBytes);
        _isPosterLoading = false;
      });
      return;
    }

    //  ########################################################################
    //  Se non è stato trovato alcun poster nel server o nella cache.

    setState(() {
      _moviePosterBytes = null;
      _isPosterLoading = false;
    });

    return;
  }

  void _showDetails() {
    if (!mounted) return;
    context.push('/movie/${widget.movie.idMovie}', extra: widget.movie);
  }

  void _showNerdStats() {
    final infoRows = [
      DataRow(
        cells: [
          const DataCell(Text('ID')),
          DataCell(SelectableText(widget.movie.idMovie)),
        ],
      ),
      DataRow(
        cells: [
          const DataCell(Text('Titolo')),
          DataCell(SelectableText(widget.movie.title ?? '')),
        ],
      ),
      DataRow(
        cells: [
          const DataCell(Text('Scelto per te')),
          DataCell(
            SelectableText((widget.movie.softmaxProb != null) ? 'Si' : 'No'),
          ),
        ],
      ),
    ];

    if (widget.movie.softmaxProb != null) {
      final prob = "${(widget.movie.softmaxProb! * 100).toStringAsFixed(4)}%";
      infoRows.add(
        DataRow(
          cells: [
            const DataCell(Text('Probabilità softmax')),
            DataCell(SelectableText(prob)),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => RecSysAlertDialog(
        topIcon: Icons.query_stats,
        alertTitle: 'Statistiche per nerd',
        alertContent: DataTable(
          columns: const [
            DataColumn(label: Text('Campo')),
            DataColumn(label: Text('Valore')),
          ],
          rows: infoRows,
        ),
      ),
    );
  }

  List<Widget> _buildMovieInfo() {
    List<Widget> ret = List.empty(growable: true);

    if (widget.movie.title != null && widget.movie.title!.isNotEmpty) {
      ret.add(
        Tooltip(
          message: widget.movie.title!,
          child: Text(
            widget.movie.title!,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (widget.movie.description != null &&
        widget.movie.description!.isNotEmpty) {
      ret.addAll([
        SizedBox(height: 12.0),
        Text(
          widget.movie.description!,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ]);
    }

    if (widget.movie.seen != null && widget.movie.rating != null) {
      final ratingType = widget.movie.seen! ? 'reale' : 'predetto';
      final rating = widget.movie.rating!;
      final ratingColor = getRatingColor(rating);

      ret.add(
        Center(
          child: Tooltip(
            message: "Rating $ratingType: ${rating.toStringAsFixed(2)}",
            child: RatingBarIndicator(
              rating: rating,
              itemCount: 5,
              unratedColor: ratingColor.withAlpha(50),
              itemBuilder: (context, _) =>
                  Icon(Icons.horizontal_rule_rounded, color: ratingColor),
            ),
          ),
        ),
      );
    }

    // if (widget.movie.subjects != null && widget.movie.subjects!.isNotEmpty) {
    //   ret.add(_buildFadingChipsRow());
    // }

    return ret;
  }

  // Widget _buildFadingChipsRow() {
  //   final allFeatures = <String>[
  //     ...widget.movie.actors ?? [],
  //     ...widget.movie.composers ?? [],
  //     ...widget.movie.directors ?? [],
  //     ...widget.movie.genres ?? [],
  //     ...widget.movie.producers ?? [],
  //     ...widget.movie.productionCompanies ?? [],
  //     ...widget.movie.subjects ?? [],
  //     ...widget.movie.writers ?? [],
  //   ];
  //   allFeatures.shuffle(Random());
  //   final chips = allFeatures.take(10).toList();
  //
  //   return SizedBox(
  //     height: 34,
  //     child: LayoutBuilder(
  //       builder: (context, constraints) {
  //         return ShaderMask(
  //           shaderCallback: (rect) {
  //             return LinearGradient(
  //               begin: Alignment.centerLeft,
  //               end: Alignment.centerRight,
  //               colors: [
  //                 Colors.transparent,
  //                 Colors.white,
  //                 Colors.white,
  //                 Colors.transparent,
  //               ],
  //               stops: [0.0, 0.1, 0.9, 1.0],
  //             ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
  //           },
  //           blendMode: BlendMode.dstIn,
  //           child: SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             physics: const BouncingScrollPhysics(),
  //             child: Row(
  //               spacing: 5,
  //               children: chips.map((feature) {
  //                 return Chip(
  //                   label: Text(
  //                     feature,
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontWeight: FontWeight.w100,
  //                       fontSize: 11.5,
  //                     ),
  //                   ),
  //                   backgroundColor: Theme.of(context).colorScheme.tertiary,
  //                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(20.0),
  //                   ),
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildChip(String message) {
    return Chip(
      label: Text(
        message,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w100,
          fontSize: 11.5,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
    );
  }

  Widget _buildButton(VoidCallback onPressed, IconData icon) {
    return IconButton(
      onPressed: onPressed,
      constraints: BoxConstraints(
        maxHeight: 34,
        maxWidth: 34,
        minWidth: 34,
        minHeight: 34,
      ),
      padding: EdgeInsets.all(0.0),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
      icon: Icon(icon, color: Colors.black, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 350,
        height: 280,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_isPosterLoading)
                      return const Center(child: CircularProgressIndicator());
                    if (_moviePosterBytes == null)
                      return const Placeholder();
                    else
                      return SoftEdgeBlur(
                        edges: [
                          EdgeBlur(
                            type: EdgeType.bottomEdge,
                            size: 200,
                            sigma: 15,
                            controlPoints: [
                              ControlPoint(
                                position: 0.5,
                                type: ControlPointType.visible,
                              ),
                              ControlPoint(
                                position: 1.0,
                                type: ControlPointType.transparent,
                              ),
                            ],
                          ),
                        ],
                        child: Image.memory(
                          _moviePosterBytes!,
                          fit: BoxFit.cover,
                        ),
                      );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    backgroundBlendMode: BlendMode.darken,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black26,
                        Colors.black87,
                        Colors.black,
                      ],
                      stops: [0.0, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.directional(
                textDirection: TextDirection.ltr,
                top: 12,
                start: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 8,
                  children: [
                    if (widget.movie.softmaxProb != null)
                      _buildChip("Scelto per te"),
                    if (widget.movie.seen ?? false) _buildChip("Già visto"),
                  ],
                ),
              ),
              Positioned.directional(
                textDirection: TextDirection.rtl,
                top: 12,
                start: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 8,
                  children: [
                    _buildButton(_showNerdStats, Icons.query_stats),
                    _buildButton(_showDetails, Icons.info_outline),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildMovieInfo(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI

//  https://dribbble.com/shots/25974845-Travel-Guide-Card-UI-Clean-Card-Design-Travel-App
//  https://api.flutter.dev/flutter/widgets/Positioned/Positioned.html
//  https://pub.dev/packages/soft_edge_blur
//  https://stackoverflow.com/questions/49211024/how-to-resize-height-and-width-of-an-iconbutton-in-flutter
//  https://stackoverflow.com/questions/51190657/flutter-how-to-blend-an-image-with-a-gradient-colour
