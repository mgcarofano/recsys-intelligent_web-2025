/*

	base_client.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe BaseClient implementa un client HTTP per effettuare richieste API
  verso il server Python, utilizzando il pacchetto "Dio" per la gestione delle
  richieste e delle risposte.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:knowledge_recsys/recsys_main.dart';

//	############################################################################
//	COSTANTI E VARIABILI

//	############################################################################
//	ALTRI METODI

extension NLDioException on DioException {
  bool get isNoConnectionError =>
      type == DioExceptionType.unknown && error is SocketException;
  bool get httpError =>
      type == DioExceptionType.unknown && error is HttpException;
  bool get connectionTimeoutError => type == DioExceptionType.connectionTimeout;
  bool get receiveTimeoutError => type == DioExceptionType.receiveTimeout;
  bool get notNullErrorResponse => response != null;
}

//	############################################################################
//	CLASSI E ROUTE

class BaseClient {
  BaseClient._privateConstructor();
  static final BaseClient instance = BaseClient._privateConstructor();
  static Dio? _client;
  static SyncState _isSynced = SyncState.notSynced;
  static String errorMessage = '';

  static const serverProtocol = 'http';
  static String _serverAddress = '192.168.59.100';
  static const serverPort = '8000';

  String get serverAddress => _serverAddress;
  set serverAddress(String address) {
    _serverAddress = address;
    _client = _initClient();
  }

  Dio get client => _client ??= _initClient();
  SyncState get isSynced {
    return _isSynced;
  }

  Dio _initClient() {
    var options = BaseOptions(
      baseUrl: '$serverProtocol://$serverAddress:$serverPort',
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 60000),
      followRedirects: false,
    );

    return Dio(options);
  }

  Future<dynamic> _getRequest(
    String api, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      var response = await client.request(
        api,
        queryParameters: params,
        options: Options(method: 'GET', responseType: ResponseType.plain),
      );

      if (response.statusCode != 200) {
        errorMessage =
            response.statusMessage ?? 'Impossibile completare la richiesta!';
        throw FormatException(errorMessage);
      }

      return response.data;
    } on DioException catch (e) {
      if (e.isNoConnectionError) {
        errorMessage = 'Sei offline!';
        throw FormatException(errorMessage);
      } else if (e.notNullErrorResponse) {
        errorMessage =
            e.response?.statusMessage ?? 'Impossibile completare la richiesta!';
        throw FormatException(errorMessage);
      } else if (e.connectionTimeoutError) {
        errorMessage = 'Impossibile connettersi al server!';
        throw FormatException(errorMessage);
      } else if (e.receiveTimeoutError) {
        errorMessage = 'La connessione è scaduta!';
        throw FormatException(errorMessage);
      } else if (e.httpError) {
        errorMessage = 'Impossibile completare la richiesta!';
        throw FormatException(errorMessage);
      } else {
        rethrow;
      }
    }
  }

  Future<dynamic> _postRequest(String api, [Map<String, dynamic>? form]) async {
    try {
      var response = await client.request(
        api,
        data: FormData.fromMap(form ?? {}),
        options: Options(method: 'POST'),
      );

      if (response.statusCode != 201) {
        throw FormatException(
          response.statusMessage ?? 'Impossibile completare la richiesta!',
        );
      }

      return response.data;
    } on DioException catch (e) {
      if (e.isNoConnectionError) {
        errorMessage = 'Sei offline!';
        throw FormatException(errorMessage);
      } else if (e.notNullErrorResponse) {
        errorMessage =
            e.response?.statusMessage ?? 'Impossibile completare la richiesta!';
        throw FormatException(errorMessage);
      } else if (e.connectionTimeoutError) {
        errorMessage = 'Impossibile connettersi al server!';
        throw FormatException(errorMessage);
      } else if (e.receiveTimeoutError) {
        errorMessage = 'La connessione è scaduta!';
        throw FormatException(errorMessage);
      } else if (e.httpError) {
        errorMessage = 'Impossibile completare la richiesta!';
        throw FormatException(errorMessage);
      } else {
        rethrow;
      }
    }
  }
}

//	############################################################################
//	RIFERIMENTI
