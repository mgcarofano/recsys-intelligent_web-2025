/*

	recsys_action_button.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe RecSysActionButton crea un pulsante personalizzato con un'icona e un
  testo, utilizzato nell'applicazione come FloatingActionButton.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

class RecSysActionButton extends StatefulWidget {
  final IconData icon;
  final String buttonText;
  final void Function() onPressed;

  const RecSysActionButton({
    super.key,
    required this.icon,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  State<RecSysActionButton> createState() => _RecSysActionButtonState();
}

class _RecSysActionButtonState extends State<RecSysActionButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.0,
      height: 95.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.primary,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.fitHeight,
                child: Icon(
                  widget.icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.buttonText,
                textAlign: TextAlign.center,
                // style: GoogleFonts.getFont(
                //   "Fascinate Inline",
                //   textStyle: Theme.of(context).textTheme.headlineLarge,
                //   color: Theme.of(context).colorScheme.onPrimary,
                // ),
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
