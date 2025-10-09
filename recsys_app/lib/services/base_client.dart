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
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// import 'package:knowledge_recsys/recsys_main.dart';

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
  // static SyncState _isSynced = SyncState.notSynced;
  static String errorMessage = '';

  static const serverProtocol = 'http';
  static String _serverAddress = 'localhost';
  static const serverPort = '8000';

  String get serverAddress => _serverAddress;
  set serverAddress(String address) {
    _serverAddress = address;
    _client = _initClient();
  }

  Dio get client => _client ??= _initClient();

  // SyncState get isSynced {
  //   return _isSynced;
  // }

  Dio _initClient() {
    var options = BaseOptions(
      baseUrl: '$serverProtocol://$serverAddress:$serverPort',
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 60000),
      followRedirects: false,
    );

    return Dio(options);
  }

  //  ##########################################################################
  //  GET REQUESTS
  //  GET is used to request data from a specified resource.

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

  Future<dynamic> getUsers() async => _getRequest('/get-users');

  Future<dynamic> getParams() async => _getRequest('/get-params');

  Future<dynamic> getMovieRecommendations() async =>
      _getRequest('/get-recommendations');

  Future<dynamic> getMovieInfo({required String idMovie, String? type}) async =>
      _getRequest('/get-movie-info', {'id': idMovie, 'type': type ?? ""});

  // Si può anche specificare la categoria da recuperare.
  // Future<dynamic> getMovieTitle({required String idMovie}) async =>
  //     _getRequest('/get-movie-info', {'id': idMovie, 'type': 'title'});

  Future<dynamic> getMoviesFromFeature({
    required String featureId,
    String? order,
  }) async => _getRequest('/get-movies', {
    'type': 'feature',
    'id': featureId,
    if (order != null) 'order': order,
  });

  Future<dynamic> getMoviesFromRatings({
    required String userId,
    String? order,
  }) async => _getRequest('/get-movies', {
    'type': 'ratings',
    'id': userId,
    if (order != null) 'order': order,
  });

  Future<dynamic> downloadMoviePoster({required String idMovie}) async {
    try {
      var response = await client.request(
        '/download-movie-poster',
        queryParameters: {'id': idMovie},
        options: Options(method: 'GET', responseType: ResponseType.bytes),
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

  //  ##########################################################################
  //  POST REQUESTS
  //  POST is used to send data to a server to create/update a resource.

  Future<dynamic> _postRequest(String api, [Map<String, dynamic>? data]) async {
    try {
      var response = await client.request(
        api,
        data: data ?? {},
        options: Options(method: 'POST'),
      );

      debugPrint(response.data);

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

  Future<dynamic> loginUser({required String userId}) async =>
      _postRequest('/login-user', {'userId': userId});

  Future<dynamic> updateParams({
    int? minSupport,
    int? movieRecommendations,
    int? topFeatures,
  }) async => _postRequest('/update-params', {
    "minSupport": minSupport,
    "movieRecommendations": movieRecommendations,
    "topFeatures": topFeatures,
  });
}

//	############################################################################
//	RIFERIMENTI

//  https://www.w3schools.com/tags/ref_httpmethods.asp
