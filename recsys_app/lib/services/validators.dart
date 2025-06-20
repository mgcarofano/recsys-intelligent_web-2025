/*

	validators.dart
  by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

  La classe Validators fornisce metodi per la validazione di email e indirizzi,
  utilizzando espressioni regolari per verificare i pattern.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

//	############################################################################
//	COSTANTI E VARIABILI

enum CheckTypes {
  emptyValue,
  notValidPatternEmail,
  notValidPatternAddress,
  validValue,
}

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI E ROUTE

abstract class Validators {
  static isEmptyValue(String value) {
    return (value.isEmpty) ? CheckTypes.emptyValue : CheckTypes.validValue;
  }

  static validateEmail(String email) {
    var isEmailValid = isEmptyValue(email);

    if (isEmailValid == CheckTypes.validValue) {
      isEmailValid = (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email))
          ? CheckTypes.notValidPatternEmail
          : CheckTypes.validValue;
    }

    return isEmailValid;
  }

  static validateAddress(String address) {
    var isAddressValid = isEmptyValue(address);

    if (isAddressValid == CheckTypes.validValue) {
      isAddressValid =
          (!RegExp(
            r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$',
          ).hasMatch(address))
          ? CheckTypes.notValidPatternAddress
          : CheckTypes.validValue;
    }

    return isAddressValid;
  }
}

//	############################################################################
//	RIFERIMENTI
