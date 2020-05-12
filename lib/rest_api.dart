import 'dart:async';

import 'options.dart';
import 'response.dart';
// This abstract class provides API to standardize the way http
// request actions such as get | put | delete | post are performed
// on a typical json based restful webservices. The concrete implementation
// of this type would implement requirements specific to that particular
// restful webservices.

// For an example, webservice1 would expect a key 'access_key'
// with some value in its header without which the webservice1
// can't be accessed. Similarly webservice2 restricts usage of
// payload in its request body for delete request.

// The following definition of the API does not provide default implementation.
// Forces the concrete types to implement default implementation, therefore
// eliminates the possibility of developers missing the implementation
// specific to that webservices for that API.
abstract class RestAPI {
  Future<Response> get(url, {dynamic data, Options options});
  Future<Response> post(url, {dynamic data, Options options});
  Future<Response> put(url, {dynamic data, Options options});
  Future<Response> delete(url, {dynamic data, Options options});
}

//Returns Type HttpAction
enum HttpAction { get, post, put, delete }
