/*

	recsys_text_form_field.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe RecSysTextFormField implementa un campo di input dal design
  personalizzato, utilizzando come base il widget TextFormField di Flutter.

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

class RecSysTextFormField extends StatefulWidget {
  final TextEditingController controller;

  final FormFieldValidator? validator;
  final FormFieldSetter? onSaved;

  final String? tooltip;
  final IconData? prefixIcon;
  final String labelText;
  final int? maxLength;

  final bool isObscured;
  final IconButton? suffixIcon;

  final TextInputAction? textInputAction;

  const RecSysTextFormField({
    super.key,
    this.validator,
    this.onSaved,
    required this.controller,
    this.tooltip,
    this.prefixIcon,
    required this.labelText,
    this.isObscured = false,
    this.suffixIcon,
    this.maxLength,
    this.textInputAction,
  });

  @override
  State<RecSysTextFormField> createState() => _RecSysTextFormFieldState();
}

class _RecSysTextFormFieldState extends State<RecSysTextFormField> {
  @override
  Widget build(BuildContext context) {
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainer,
      prefixIcon: Icon(
        widget.prefixIcon,
        size: 25.0,
        color: Theme.of(context).colorScheme.primary,
      ),
      suffixIcon: widget.suffixIcon,
      contentPadding: EdgeInsets.all(35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      floatingLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.inverseSurface,
      ),
      labelText: widget.labelText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      errorMaxLines: 3,
    );

    return Tooltip(
      message: widget.tooltip ?? "",
      child: TextFormField(
        enabled: true,
        autocorrect: false,
        obscureText: widget.isObscured,
        textAlign: TextAlign.start,
        maxLength: widget.maxLength,
        cursorHeight: 15,
        validator: widget.validator ?? (value) => null,
        onSaved: widget.onSaved,
        controller: widget.controller,
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: fieldDecoration,
        textInputAction: widget.textInputAction ?? TextInputAction.none,
      ),
    );
  }
}

//	############################################################################
//	RIFERIMENTI
