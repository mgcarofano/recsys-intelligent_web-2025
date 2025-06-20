/*

	recsys_app_bar.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

  La classe RecSysAppBar crea una AppBar personalizzata per l'applicazione,
  pensata per offrire un aspetto coerente con l’identità visiva
  dell'applicazione.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class RecSysAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  final String title;
  final Alignment alignment;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const RecSysAppBar({
    super.key,
    required this.title,
    required this.alignment,
    this.actions,
    this.onTap,
  });

  @override
  State<RecSysAppBar> createState() => _RecSysAppBarState();
}

class _RecSysAppBarState extends State<RecSysAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      title: GestureDetector(
        onTap: widget.onTap,
        child: Align(alignment: widget.alignment, child: Text(widget.title)),
      ),
      actions: widget.actions ?? [],
    );
  }
}

//	############################################################################
//	RIFERIMENTI
