import 'dart:async';
import 'dart:io';

import 'options.dart';
import 'response.dart';
import 'rest_api.dart';
import 'rest_service_api.dart';

class BaseAPI implements RestAPI {
  static final BaseAPI _singleton = new BaseAPI._internal();

  //The RestServiceAPI used for all restful calls to the base API.
  static RestServiceAPI _restServiceAPI;

  factory BaseAPI() {
    return _singleton;
  }

  BaseAPI._internal() {
    // initialization logic here
    if (_restServiceAPI == null) {
      _restServiceAPI = new RestServiceAPI(getFuseOptions());
    }
  }

  ///The second factor ID is used for second fqctr and to load the customer and accounts
  static Options getFuseOptions() {
    Options defaultOptions = new Options(
        contentType: ContentType.json,
        connectTimeout: 5000,
        receiveTimeout: 3000);
    Options secureOptions = defaultOptions.merge();
    return secureOptions;
  }

  Future<Response> get(url, {dynamic data, options}) async {
    Map filteredData;

    if (data is Map) {
      filteredData = Map.from(data);
      data.forEach((key, value) {
        if (url.contains('{$key}')) {
          url = url.replaceAll('{$key}', value);
          filteredData.remove(key);
        }
      });
      if (filteredData != null && filteredData.isEmpty) {
        filteredData = null;
        data = null;
      }
    }

    return getFromApi(url, data: data);
  }

  Future<Response> getFromApi(url, {dynamic data, options}) async {
    Future<Response> response = _restServiceAPI.get(
      url,
      data: data,
      options: (options != null) ? options : getFuseOptions(),
    );

    return response;
  }

  Future<Response> post(url, {dynamic data, options}) async {
    Future<Response> response = _restServiceAPI.post(
      url,
      data: data,
      options: (options != null) ? options : getFuseOptions(),
    );

    return response;
  }

  Future<Response> put(url, {dynamic data, options}) async {
    Map filteredData;

    if (data is Map) {
      filteredData = Map.from(data);
      data.forEach((key, value) {
        if (url.contains('{$key}')) {
          url = url.replaceAll('{$key}', value);
          filteredData.remove(key);
        }
      });
      if (filteredData != null && filteredData.isEmpty) {
        filteredData = null;
        data = null;
      }
    }

    Future<Response> response = _restServiceAPI.put(url,
        data: filteredData ?? data,
        options: (options != null) ? options : getFuseOptions());

    return response;
  }

  Future<Response> delete(url, {dynamic data, options}) async {
    Map filteredData;

    if (data is Map) {
      filteredData = Map.from(data);
      data.forEach((key, value) {
        if (url.contains('{$key}')) {
          url = url.replaceAll('{$key}', value);
          filteredData.remove(key);
        }
      });
      if (filteredData != null && filteredData.isEmpty) {
        filteredData = null;
        data = null;
      }
    }

    Future<Response> response = _restServiceAPI.delete(url,
        data: filteredData ?? data,
        options: (options != null) ? options : getFuseOptions());

    return response;
  }
}
