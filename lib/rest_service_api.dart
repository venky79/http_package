import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'options.dart';
import 'response.dart';
import 'restapi_error.dart';

/// Rest client for Flutter
class RestServiceAPI {
  static const HTTP_ACTION_GET = "GET";
  static const HTTP_ACTION_POST = "POST";
  static const HTTP_ACTION_PUT = "PUT";
  static const HTTP_ACTION_DELETE = "DELETE";

  /// Create RestServiceAPI instance with default [Options]  and CookieJar.
  /// It's mostly just one RestServiceAPI instance in your application.
  RestServiceAPI(Options options) {
    if (options == null) {
      options = new Options();
    }
    this.options = options;
  }

  /// Default Request config. More see [Options] .
  Options options;

  Set<Cookie> sessionCookies = new Set<Cookie>();

  /// [RestServiceAPI] will create new HttpClient when it is needed.

  HttpClient _httpClient = new HttpClient();

  /// Handy method to make http GET request, which is a alias of  [RestServiceAPI.request].
  Future<Response<T>> get<T>(String path, {data, Options options}) {
    return _request<T>(path,
        data: data,
        options: _checkOptions(HTTP_ACTION_GET, options),
        httpClient: _httpClient);
  }

  /// Handy method to make http POST request, which is a alias of  [RestServiceAPI.request].
  Future<Response<T>> post<T>(String path, {data, Options options}) {
    return _request<T>(path,
        data: data,
        options: _checkOptions(HTTP_ACTION_POST, options),
        httpClient: _httpClient);
  }

  /// Handy method to make http PUT request, which is a alias of  [RestServiceAPI.request].
  Future<Response<T>> put<T>(String path, {data, Options options}) {
    return _request<T>(path,
        data: data,
        options: _checkOptions(HTTP_ACTION_PUT, options),
        httpClient: _httpClient);
  }

  /// Handy method to make http DELETE request, which is a alias of  [RestServiceAPI.request].
  Future<Response<T>> delete<T>(String path, {data, Options options}) {
    return _request(path,
        data: data,
        options: _checkOptions(HTTP_ACTION_DELETE, options),
        httpClient: _httpClient);
  }

  /// Make http request with options.
  ///
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  ///  [httpClient] The httpClient.

  Future<Response<T>> _request<T>(String path,
      {data, Options options, HttpClient httpClient}) async {
    Future<Response<T>> future = _checkIfNeedEnqueue<T>(() {
      _mergeOptions(options);
      options.data = data ?? options.data;
      options.path = path;
      // make request
      return _makeRequest<T>(options, httpClient);
    });
    return future.then((d) {
      return d;
    });
  }

  Future<Response<T>> _makeRequest<T>(Options options,
      [HttpClient httpClient]) async {
    HttpClientResponse response;
    try {
      // Normalize the url.
      String url = options.path;
      if (!url.startsWith(new RegExp(r"https?:"))) {
        url = options.baseUrl + url;
        List<String> s = url.split(":/");
        url = s[0] + ':/' + s[1].replaceAll("//", "/");
      }
      //options.method = options.method.toUpperCase();
      bool isGet = options.method == HTTP_ACTION_GET;
      bool isDelete = options.method == HTTP_ACTION_DELETE;

      if ((isGet && options.data is Map) || (isDelete && options.data is Map)) {
        url += (url.contains("?") ? "&" : "?") + _urlEncodeMap(options.data);
      }
      Uri uri = Uri.parse(url).normalizePath();
      Future requestFuture;

      if (options.connectTimeout > 0) {
        requestFuture = httpClient
            .openUrl(options.method, uri)
            .timeout(new Duration(milliseconds: options.connectTimeout));
      } else {
        requestFuture = httpClient.openUrl(options.method, uri);
      }
      HttpClientRequest request;
      try {
        request = await requestFuture;
      } on TimeoutException {
        throw new RestServiceAPIError(
          message: "Connecting timeout[${options.connectTimeout}ms]",
          type: RestServiceAPIErrorType.CONNECT_TIMEOUT,
        );
      }
      request.followRedirects = options.followRedirects;
      if (sessionCookies != null && request.cookies != null) {
        request.cookies.addAll(sessionCookies);
      }

      try {
        if (!isGet && !isDelete) {
          // Transform the request data, set headers inner.
          await _transformData(options, request);
        } else {
          _setHeaders(options, request);
        }
      } catch (e) {
        //If user cancel  the request in transformer, close the connect by hand.
        request.addError(e);
      }

      response = await request.close();

      var retData = await _transformResponse(options, response);

      Response ret = new Response(
          data: retData,
          headers: response.headers,
          request: options,
          statusCode: response.statusCode);

      Future<Response<T>> future = _checkIfNeedEnqueue<T>(() {
        if (options.validateStatus(response.statusCode)) {
          return _onSuccess<T>(ret);
        } else {
          var err = new RestServiceAPIError(
            response: ret,
            message: 'Http status error [${response.statusCode}]',
            type: RestServiceAPIErrorType.RESPONSE,
          );
          return _onError(err);
        }
      });

      return future;
    } catch (e) {
      RestServiceAPIError err = _assureRestServiceAPIError(e);

      // Response onError
      Future<Response<T>> future = _checkIfNeedEnqueue<T>(() {
        // Listen in error interceptor.
        return _onError(err);
      });
      // Listen if in the queue.
      return future;
    }
  }

  _transformData(Options options, HttpClientRequest request) async {
    var data = options.data;
    List<int> bytes;
    if (data != null) {
      options.headers[HttpHeaders.contentTypeHeader] =
          options.contentType.toString();

      // Call request transformer.
      String _data = await _transformRequest(options);

      // Set the headers, must before `request.write`
      _setHeaders(options, request);

      // Convert to utf8
      bytes = utf8.encode(_data);

      // Set Content-Length
      request.headers.set(HttpHeaders.contentLengthHeader, bytes.length);

      request.add(bytes);
    } else {
      _setHeaders(options, request);
    }
  }

// Transform current Future status("success" and "error") if necessary
  Future<Response<T>> _transFutureStatusIfNecessary<T>(Future future) {
    return future.then<Response<T>>((data) {
      // Strictly be a RestServiceAPIError instance, but we relax the restrictions
      // if (data is RestServiceAPIError)
      if (data is Error) {
        return _reject<T>(data);
      }
      return _resolve<T>(data);
    }, onError: (err) {
      if (err is Response) {
        return _resolve<T>(err);
      }
      return _reject<T>(err);
    });
  }

  Future<Response<T>> _onSuccess<T>(response) {
    if (response is! Future) {
      // Assure response is a Future
      response = new Future.value(response);
    }
    return _transFutureStatusIfNecessary<T>(response);
  }

  Future<Response<T>> _onError<T>(err) {
    if (err is! Future) {
      err = new Future.error(err);
    }
    return _transFutureStatusIfNecessary<T>(err);
  }

  _mergeOptions(Options opt) {
    opt.headers = (new Map.from(options.headers))..addAll(opt.headers);
    opt.baseUrl ??= options.baseUrl ?? "";
    opt.connectTimeout ??= options.connectTimeout ?? 0;
    opt.receiveTimeout ??= options.receiveTimeout ?? 0;
    opt.responseType ??= options.responseType ?? ResponseType.JSON;
    opt.data ??= options.data;
    opt.extra = (new Map.from(options.extra))..addAll(opt.extra);
    opt.validateStatus ??= options.validateStatus ??
        (int status) => status >= 200 && status < 300 || status == 304;
    opt.followRedirects ??= options.followRedirects ?? true;
  }

  Options _checkOptions(method, options) {
    if (options == null) {
      options = new Options();
    }
    options.method = method;
    return options;
  }

  Future<Response<T>> _checkIfNeedEnqueue<T>(callback()) {
    return callback();
  }

  RestServiceAPIError _assureRestServiceAPIError(err) {
    if (err is RestServiceAPIError) {
      return err;
    } else if (err is Error) {
      err = new RestServiceAPIError(
          response: null, message: err.toString(), stackTrace: err.stackTrace);
    } else {
      err = new RestServiceAPIError(message: err.toString());
    }
    return err;
  }

  Response<T> _assureResponse<T>(response) {
    if (response is Response<T>) {
      return response;
    } else if (response is! Response) {
      response = new Response<T>(data: response);
    } else {
      T data = response.data;
      response = new Response<T>(data: data);
    }
    return response;
  }

  void _setHeaders(Options options, HttpClientRequest request) {
    options.headers.forEach((k, v) => request.headers.set(k, v));
  }

  Future<String> _transformRequest(Options options) async {
    var data = options.data ?? "";
    if (data is! String) {
      if (options.contentType.mimeType == ContentType.json.mimeType) {
        var encoded = json
            .encode(options.data)
            .replaceAll('\’', '\'')
            .replaceAll('\”', '\"')
            .replaceAll('\‘', '\'');
        return encoded;
      } else if (data is Map) {
        return _urlEncodeMap(data);
      }
    }
    return data.toString();
  }

  /// As an agreement, you must return the [response]
  /// when the Options.responseType is [ResponseType.STREAM].
  Future _transformResponse(
      Options options, HttpClientResponse response) async {
    if (options.responseType == ResponseType.STREAM) {
      return response;
    }
    // Handle timeout
    Stream<List<int>> stream = response;
    if (options.receiveTimeout > 0) {
      stream = stream
          .timeout(new Duration(milliseconds: options.receiveTimeout),
              onTimeout: (EventSink sink) {
        sink.addError(new RestServiceAPIError(
          message: "Receiving data timeout[${options.receiveTimeout}ms]",
          type: RestServiceAPIErrorType.RECEIVE_TIMEOUT,
        ));
        sink.close();
      });
    }
    String responseBody =
        await stream.transform(Utf8Decoder(allowMalformed: true)).join();
    if (responseBody != null &&
        responseBody.trim().isNotEmpty &&
        response.headers.contentType?.mimeType == ContentType.json.mimeType) {
      return json.decode(responseBody);
    }

    return responseBody;
  }

  /// Deep encode the [Map<String, dynamic>] to percent-encoding.
  /// It is mostly used with  the "application/x-www-form-urlencoded" content-type.
  static String _urlEncodeMap(data) {
    StringBuffer urlData = new StringBuffer("");
    bool first = true;
    void urlEncode(dynamic sub, String path) {
      if (sub is List) {
        for (int i = 0; i < sub.length; i++) {
          urlEncode(sub[i], "$path%5B%5D");
        }
      } else if (sub is Map) {
        sub.forEach((k, v) {
          if (path == "") {
            urlEncode(v, "${Uri.encodeQueryComponent(k)}");
          } else {
            urlEncode(v, "$path%5B${Uri.encodeQueryComponent(k)}%5D");
          }
        });
      } else {
        if (!first) {
          urlData.write("&");
        }
        first = false;
        urlData.write("$path=${Uri.encodeQueryComponent(sub.toString())}");
      }
    }

    urlEncode(data, "");
    return urlData.toString();
  }

  /// Assure the final future state is succeed!
  Future<Response<T>> _resolve<T>(response) {
    if (response is! Future) {
      response = new Future.value(response);
    }
    return response.then<Response<T>>((data) {
      return _assureResponse<T>(data);
    }, onError: (err) {
      // transform "error" to "success"
      return _assureResponse<T>(err);
    });
  }

  /// Assure the final future state is failed!
  Future<Response<T>> _reject<T>(err) {
    if (err is! Future) {
      err = new Future.error(err);
    }
    return err.then<Response<T>>((v) {
      //TODO This will cause cached API errors happen twice, we will
      //TODO have to find out a way to fix it while not breaking
      //TODO create web seal requests.
      throw _assureRestServiceAPIError(v);
    }, onError: (e) {
      //TODO Same as above
      throw _assureRestServiceAPIError(e);
    });
  }
}
