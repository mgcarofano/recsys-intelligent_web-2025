/*

	recsys_movie_card.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/services/base_client.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

// TODO: convertire in StatefulWidget e implementare InitState con caricamento unico delle immagini e altre info
// TODO: implementare click sulla card con stato selezionato / non selezionato
class RecSysMovieCard extends StatelessWidget {
  final String idMovie;
  final String title;
  final String description;
  final List<String> subjects;

  RecSysMovieCard({
    super.key,
    required this.idMovie,
    required this.title,
    required this.description,
    required this.subjects,
  });

  Future<Uint8List> _getRawMoviePoster(String idMovie) async {
    var data = await BaseClient.instance.downloadMoviePoster(idMovie: idMovie);

    if (data != null)
      return Uint8List.fromList(data!);
    else
      throw Exception("Impossibile scaricare l'immagine");
  }

  void _showDetails() {
    // TODO: naviga alla pagina dettagli del movie selezionato
  }

  Widget _buildFadingChipsRow(List<String> subjects) {
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
              stops: [0.0, 0.2, 0.8, 1.0],
            ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              spacing: 5,
              children: subjects.map((subject) {
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
              child: FutureBuilder(
                future: _getRawMoviePoster(idMovie),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      return const Center(child: CircularProgressIndicator());
                    case ConnectionState.done:
                      if (snapshot.hasError)
                        return const Center(child: Icon(Icons.broken_image));
                      else
                        return SoftEdgeBlur(
                          edges: [
                            EdgeBlur(
                              type: EdgeType.bottomEdge,
                              size: 200,
                              sigma: 10,
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
                            snapshot.data!,
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
                decoration: const BoxDecoration(
                  backgroundBlendMode: BlendMode.darken,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black12,
                      Colors.black26,
                      Colors.black,
                    ],
                    stops: [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
                padding: EdgeInsets.all(20.0),
                child: Column(
                  spacing: 12.0,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 30, child: _buildFadingChipsRow(subjects)),
                  ],
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

//  https://api.flutter.dev/flutter/widgets/Positioned/Positioned.html
//  https://pub.dev/packages/soft_edge_blur
