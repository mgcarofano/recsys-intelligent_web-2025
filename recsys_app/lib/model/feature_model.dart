/*

	feature_model.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe Feature rappresenta una caratteristica di un film.
  Ognuna di esse ha un identificativo univoco, una categoria
  (es. genres, directors, ...), il nome che, appunto, la descrive e una
  valutazione media basata sulle valutazioni degli utenti.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:knowledge_recsys/recsys_main.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class Feature {
  final String featureId;
  final String category;
  final String name;
  final double rating;

  Feature({
    required this.featureId,
    required this.category,
    required this.name,
    required this.rating,
  });

  Widget toTable() {
    final ratingColor = getRatingColor(rating);

    return DataTable(
      columns: const [
        DataColumn(label: Text('Campo')),
        DataColumn(label: Text('Valore')),
      ],
      rows: [
        DataRow(
          cells: [
            const DataCell(Text('ID')),
            DataCell(SelectableText(featureId)),
          ],
        ),
        DataRow(
          cells: [
            const DataCell(Text('Categoria')),
            DataCell(SelectableText(category)),
          ],
        ),
        DataRow(
          cells: [const DataCell(Text('Nome')), DataCell(SelectableText(name))],
        ),
        DataRow(
          cells: [
            const DataCell(Text('Rating medio')),
            DataCell(
              Tooltip(
                message: rating.toStringAsFixed(2),
                child: RatingBarIndicator(
                  rating: rating,
                  itemCount: 5,
                  unratedColor: ratingColor.withAlpha(50),
                  itemBuilder: (context, _) =>
                      Icon(Icons.horizontal_rule_rounded, color: ratingColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  String toString() {
    return '''Feature{
      id: $featureId,
      category: $category,
      name: $name,
      average_rating: $rating,
    }''';
  }
}

//	############################################################################
//	RIFERIMENTI
