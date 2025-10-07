/*

	feature_model.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe Feature rappresenta una caratteristica di un film. Ognuna di esse ha un identificativo univoco, una categoria (es. genres, directors, ...), il nome che, appunto, la descrive e una valutazione media basata sulle valutazioni degli utenti.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

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
