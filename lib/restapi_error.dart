import 'response.dart';

enum RestServiceAPIErrorType {
  /// Default error type, usually occurs before connecting the server.
  DEFAULT,

  /// When opening  url timeout, it occurs.
  CONNECT_TIMEOUT,

  ///  Whenever more than [receiveTimeout] (in milliseconds) passes between two events from response stream,
  ///  [RestServiceAPI] will throw the [RestServiceAPIError] with [RestServiceAPIErrorType.RECEIVE_TIMEOUT].
  ///
  ///  Note: This is not the receiving time limitation.
  RECEIVE_TIMEOUT,

  /// When the server response, but with a incorrect status, such as 404, 503...
  RESPONSE,

  APPLICATION
}

///RestServiceAPIError describes the error info  when request failed.

class RestServiceAPIError extends Error {
  RestServiceAPIError(
      {this.response,
      this.message,
      this.type = RestServiceAPIErrorType.DEFAULT,
      this.stackTrace});

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response response;

  /// Error descriptions.
  String message;

  RestServiceAPIErrorType type;

  String toString() {
    return "RestServiceAPIError [$type]: " +
        message +
        (stackTrace ?? "").toString();
  }

  /// Error stacktrace info
  StackTrace stackTrace;
}
