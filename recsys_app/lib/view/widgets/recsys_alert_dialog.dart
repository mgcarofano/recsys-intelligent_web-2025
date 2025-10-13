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
  final Widget alertContent;

  final bool? isCancelActive;
  final VoidCallback? onPressCancel;
  final String? cancelText;

  final VoidCallback? onPressConfirm;
  final String? confirmText;

  const RecSysAlertDialog({
    super.key,
    required this.topIcon,
    required this.alertTitle,
    required this.alertContent,
    this.isCancelActive,
    this.onPressCancel,
    this.cancelText,
    this.onPressConfirm,
    this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(topIcon, size: 25.0, color: Colors.grey.shade50),
      title: Center(child: Text(alertTitle)),
      content: SingleChildScrollView(child: alertContent),
      actions: [
        if (isCancelActive ?? true)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              foregroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
            onPressed: onPressCancel ?? () => context.pop(),
            child: Text(cancelText ?? 'Annulla'),
          ),
        if (onPressConfirm != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: onPressConfirm ?? () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(confirmText ?? 'Si'),
            ),
          ),
      ],
    );
  }
}

//	############################################################################
//	RIFERIMENTI
