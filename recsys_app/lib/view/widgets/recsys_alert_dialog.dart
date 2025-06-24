/*

	recsys_alert_dialog.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

  La classe RecSysAlertDialog fornisce un widget personalizzato per visualizzare
  un dialogo di avviso.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class RecSysAlertDialog extends StatelessWidget {
  final IconData topIcon;
  final String alertTitle;
  final String alertMessage;

  final VoidCallback? onPressCancel;
  final String? cancelText;

  final VoidCallback? onPressConfirm;
  final String? confirmText;

  const RecSysAlertDialog({
    super.key,
    required this.topIcon,
    required this.alertTitle,
    required this.alertMessage,
    this.onPressCancel,
    this.cancelText,
    this.onPressConfirm,
    this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(topIcon, size: 25.0, color: Colors.grey.shade50),
      title: Center(
        child: Text(
          alertTitle,
          // style: Theme.of(context).textTheme.headline2?.copyWith(
          //   color: Colors.grey.shade50
          // ),
        ),
      ),
      content: Text(
        alertMessage,
        // style: Theme.of(context).textTheme.headline4?.copyWith(
        //   color: Colors.grey.shade50
        // )
      ),
      actions: [
        OutlinedButton(
          onPressed: onPressCancel ?? () => context.pop(),
          child: Text(
            cancelText ?? 'Annulla',
            // style: Theme.of(context).textTheme.headline5?.copyWith(
            //     color: Colors.grey.shade50
            // ),
          ),
        ),
        TextButton(
          onPressed: onPressConfirm ?? () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade50,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              confirmText ?? 'Si',
              // style: Theme.of(context).textTheme.headline5?.copyWith(
              //     color: Colors.grey.shade50
              // ),
            ),
          ),
        ),
      ],
    );
  }
}

//	############################################################################
//	RIFERIMENTI
