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

class RecSysMovieCard extends StatelessWidget {
  final String idMovie;
  final String title;
  final String description;
  final List<String> subjects;

  const RecSysMovieCard({
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
    // TODO: visualizzazione subjects
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 240,
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
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                },
              ),
            ),
            // Positioned.directional(
            //   textDirection: TextDirection.rtl,
            //   top: 20,
            //   start: 20,
            //   child: Container(
            //     padding: EdgeInsets.all(5.0),
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(100),
            //     ),
            //     child: TextButton.icon(
            //       onPressed: _showDetails,
            //       icon: const Icon(Icons.info_outline, color: Colors.black),
            //       label: const Text(
            //         'Vedi dettagli',
            //         style: TextStyle(color: Colors.black),
            //       ),
            //       style: TextButton.styleFrom(
            //         // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //         minimumSize: Size.zero,
            //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //       ),
            //     ),
            //   ),
            // ),
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Padding(
            //     padding: const EdgeInsets.all(20.0),
            //     child: SoftEdgeBlur(
            //       edges: [
            //         EdgeBlur(
            //           type: EdgeType.bottomEdge,
            //           size: 100,
            //           sigma: 30,
            //           controlPoints: [
            //             ControlPoint(
            //               position: 0.0,
            //               type: ControlPointType.visible,
            //             ),
            //             ControlPoint(
            //               position: 1.0,
            //               type: ControlPointType.transparent,
            //             ),
            //           ],
            //         ),
            //       ],
            //       child: Column(
            //         spacing: 8.0,
            //         mainAxisSize: MainAxisSize.min,
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             title,
            //             style: Theme.of(context).textTheme.headlineLarge
            //                 ?.copyWith(
            //                   color: Colors.white,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //             maxLines: 1,
            //             overflow: TextOverflow.fade,
            //           ),
            //           Text(
            //             description,
            //             style: Theme.of(
            //               context,
            //             ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            //             maxLines: 3,
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //           SizedBox(
            //             height: 34,
            //             child: _buildFadingChipsRow(subjects),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
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
