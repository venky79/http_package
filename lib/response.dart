import 'dart:io';

import 'options.dart';

/// Response describes the http Response info.

class Response<T> {
  static const int HTTP_RESPONSE_CODE_SUCCESS = 200;
  static const int HTTP_RESPONSE_CODE_SUCCESSFUL_CREATION = 201;

  static const int HTTP_RESPONSE_CODE_SUCCESSFUL_REDIRECTION = 302;
  //Second factor service returned 400 for INVALID_CREDENTIALS, ACCOUNT_LOCKED, SUSPENDED
  static const int HTTP_RESPONSE_CODE_400 = 400;
  static const int HTTP_RESPONSE_CODE_UNAUTHORIZED = 401;
  static const int HTTP_RESPONSE_CODE_FORBIDDEN = 403;
  static const int HTTP_RESPONSE_CODE_CONFLICT = 409;
  static const int HTTP_RESPONSE_CODE_SERVER_ERROR = 500;

  Response(
      {this.data,
        this.headers,
        this.request,
        this.statusCode = 0});

  /// Response body. may have been transformed, please refer to [ResponseType].
  T data;

  /// Response headers.
  HttpHeaders headers;

  /// The corresponding request info.
  Options request;

  /// Http status code.
  int statusCode;

  /// Custom field that you can retrieve it later in `then`.
  Map<String, dynamic> extra;

  @override
  String toString() => """
  Response:
    statusCode: $statusCode
    data: $data
  """;

  bool isSuccessful() {
    return this.statusCode == HTTP_RESPONSE_CODE_SUCCESS ||
        this.statusCode == HTTP_RESPONSE_CODE_SUCCESSFUL_CREATION;
  }
}