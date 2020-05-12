import 'dart:io';

import 'rest_service_api.dart';

/// ResponseType indicates which transformation should
/// be automatically applied to the response data by RestServiceAPI.
enum ResponseType {
  /// Transform the response data to JSON object.
  JSON,

  /// Get the response stream without any transformation.
  STREAM,

  /// Transform the response data to a String encoded with UTF8.
  PLAIN
}

typedef bool ValidateStatus(int status);

///The Options class describes the http request information and configuration.

class Options {
  Options(
      {this.method,
        this.baseUrl,
        this.connectTimeout,
        this.receiveTimeout,
        this.path,
        this.data,
        this.extra,
        this.headers,
        this.responseType,
        this.contentType,
        this.validateStatus,
        this.followRedirects: true}) {
    // set the default user-agent with RestServiceAPI version
    this.headers = headers ?? {};

    this.extra = extra ?? {};
  }

  /// Create a new Option from current instance with merging attributes.
  Options merge(
      {String method,
        String baseUrl,
        String path,
        int connectTimeout,
        int receiveTimeout,
        dynamic data,
        Map<String, dynamic> extra,
        Map<String, dynamic> headers,
        ResponseType responseType,
        ContentType contentType,
        ValidateStatus validateStatus,
        bool followRedirects}) {
    return new Options(
        method: method ?? this.method,
        baseUrl: baseUrl ?? this.baseUrl,
        path: path ?? this.path,
        connectTimeout: connectTimeout ?? this.connectTimeout,
        receiveTimeout: receiveTimeout ?? this.receiveTimeout,
        data: data ?? this.data,
        extra: extra ?? new Map.from(this.extra ?? {}),
        headers: headers ?? new Map.from(this.headers ?? {}),
        responseType: responseType ?? this.responseType,
        contentType: contentType ?? this.contentType,
        validateStatus: validateStatus ?? this.validateStatus,
        followRedirects: followRedirects ?? this.followRedirects);
  }

  /// Http method.
  String method;

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  /// Http request headers.
  // Map<String, dynamic> headers;
  Map<String, String> headers;

  /// Timeout in milliseconds for opening  url.
  int connectTimeout;

  ///  Whenever more than [receiveTimeout] (in milliseconds) passes between two events from response stream,
  ///  [RestServiceAPI] will throw the [RestServiceAPIError] with [RestServiceAPIErrorType.RECEIVE_TIMEOUT].
  ///
  ///  Note: This is not the receiving time limitation.
  int receiveTimeout;

  /// Request data, can be any type.
  dynamic data;

  /// If the `path` starts with "http(s)", the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path = "";

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with "application/x-www-form-urlencoded",
  /// you can set `ContentType.parse("application/x-www-form-urlencoded")`, and [RestServiceAPI]
  /// will automatically encode the request body.
  ContentType contentType;

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `JSON`, `STREAM`, `PLAIN`.
  ///
  /// The default value is `JSON`, RestServiceAPI will parse response string to json object automatically
  /// when the content-type of response is "application/json".
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `STREAM`.
  ///
  /// If you want to receive the response data with String, use `PLAIN`.
  ResponseType responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus validateStatus;

  /// Custom field that you can retrieve it later in  [Response] object.
  Map<String, dynamic> extra;

  /// see [HttpClientRequest.followRedirects]
  bool followRedirects;

  @override
  String toString() {
    return """
    =================Options=================
    method: $method
    baseUrl: $baseUrl
    connectTimeout: $connectTimeout
    receiveTimeout: $receiveTimeout
    path: $path
    data: $data
    extra: $extra
    headers: $headers
    responseType: $responseType
    contentType: $contentType
    validateStatus: $validateStatus
    followRedirects: $followRedirects
    ==============End of Options=============
    """;
  }
}
