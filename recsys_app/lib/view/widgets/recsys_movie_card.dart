/*

	recsys_movie_card.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe RecSysMovieCard rappresenta una card che visualizza le informazioni
  su un film raccomandato dal sistema, inclusi il titolo, la descrizione e i
  subjects associati. La card include anche la copertina del film, che viene
  scaricata dal server se non è già presente nella cache locale.
  L'utente può cliccare sulla card per selezionarla in modo da aggiornare le
  proprie preferenze e migliorare le raccomandazioni future.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/cache/poster_cache.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/services/base_client.dart';
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
    // TODO: naviga alla pagina dettagli del movie selezionato
  }

  List<Widget> _buildMovieInfo() {
    List<Widget> ret = List.empty(growable: true);

    if (widget.movie.title != null) {
      ret.add(
        Text(
          widget.movie.title!,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.fade,
        ),
      );
    }

    if (widget.movie.description != null) {
      ret.add(
        Text(
          widget.movie.description!,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (widget.movie.subjects != null) {
      ret.add(SizedBox(height: 30, child: _buildFadingChipsRow()));
    }

    return ret;
  }

  Widget _buildFadingChipsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.1, 0.9, 1.0],
            ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              spacing: 5,
              children: widget.movie.subjects!.map((subject) {
                return Chip(
                  label: Text(
                    subject,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w100,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  else {
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
                  }
                },
              ),
            ),
            Positioned.directional(
              textDirection: TextDirection.rtl,
              top: 12,
              start: 12,
              child: IconButton(
                onPressed: _showDetails,
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
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                // decoration: const BoxDecoration(
                //   backgroundBlendMode: BlendMode.darken,
                //   gradient: LinearGradient(
                //     begin: Alignment.topCenter,
                //     end: Alignment.bottomCenter,
                //     colors: [
                //       Colors.transparent,
                //       Colors.black26,
                //       Colors.black87,
                //       Colors.black,
                //     ],
                //     stops: [0.0, 0.6, 0.8, 1.0],
                //   ),
                // ),
                padding: EdgeInsets.all(20.0),
                child: Column(
                  spacing: 12.0,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildMovieInfo(),
                ),
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

//  https://dribbble.com/shots/25974845-Travel-Guide-Card-UI-Clean-Card-Design-Travel-App
//  https://api.flutter.dev/flutter/widgets/Positioned/Positioned.html
//  https://pub.dev/packages/soft_edge_blur
//  https://stackoverflow.com/questions/49211024/how-to-resize-height-and-width-of-an-iconbutton-in-flutter
