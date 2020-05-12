library httppackage;

import 'package:meta/meta.dart';

import 'base_api.dart';
import 'options.dart';
import 'response.dart';
import 'rest_api.dart';
import 'restapi_error.dart';

abstract class JsonResponse {
  JsonResponse.fromJson(Map<String, dynamic> json);

  String toString();
}

abstract class JsonRequestData {
  dynamic toJson();

  String toString();
}

abstract class BaseService<T, U extends BaseServiceResponseHandler> {
  final String url;
  final HttpAction action;
  final U handler;
  final Options options;
  RestAPI restApi;

  BaseService(
      {@required this.url,
      @required this.action,
      @required this.handler,
      this.restApi,
      this.options})
      : assert(url != null && url.isNotEmpty),
        assert(handler != null),
        assert(action != null) {
    restApi ??= BaseAPI();
  }

  Future<T> request({JsonRequestData data}) async {
    var jsonData;
    try {
      jsonData = data?.toJson();
    } on Error catch (e) {
      handler.onInvalidRequest(e);
      return null;
    }

    Response response;

    //TODO This switch is awkward, allow fuse to do a generic request
    //TODO like in rest_api, by sending the action as parameter
    try {
      switch (action) {
        case HttpAction.get:
          response = await restApi.get(url, data: jsonData, options: options);

          break;
        case HttpAction.post:
          response = await restApi.post(url, data: jsonData, options: options);
          break;
        case HttpAction.put:
          response = await restApi.put(url, data: jsonData, options: options);
          break;
        case HttpAction.delete:
          response =
              await restApi.delete(url, data: jsonData, options: options);
          break;
        default:
          throw 'Service not implemented';
          break;
      }
    } on RestServiceAPIError catch (e) {
      if (!serviceErrorHandler(e.response, handler))
        handler.restApiError(e.response);
      return null;
    }

    if (response != null && response.isSuccessful()) {
      try {
        if (!(response.data is Map)) response.data = null;
        var parsedResponse = parseJson(response.data);

        // If it is the 'response' from sorry server then parseJson(response.data)
        // would just return an 'non-null empty' object or partially filled object if the fields
        // are assigned with default values. It is difficult to find if the object is empty because
        // the type is known only at runtime.
        // And the reverse is not true, meaning an empty object does not confirm that the response
        // from sorry server.
        // Therefore the following code checks if response contains a Key that is specific to
        // sorry server response. if it has, then it calls onMaintenanceWindow on handler and
        // skip normal flow.
        if (response.data != null) {
          if (response.data["EmergencyMaintWindow"] != null ||
              response.data["ScheduledMaintWindow"] != null) {
            handler.onMaintenanceWindow(response.data);
          } else
            return parsedResponse;
        } else
          return parsedResponse;
      } on Error catch (e) {
        //TODO Add logger logic here
        handler.onUnexpectedContent(
            Exception(e.toString() + e.stackTrace.toString()));
      }
    } else if (response != null &&
        (response.statusCode == Response.HTTP_RESPONSE_CODE_UNAUTHORIZED ||
            response.statusCode == Response.HTTP_RESPONSE_CODE_FORBIDDEN)) {
      //TODO Add logger logic here
      handler.onInvalidSession();
    } else {
      //TODO Add logger logic here
      if (!serviceErrorHandler(response, handler)) handler.onServerError();
    }

    return null;
  }

  T parseJson(Map<String, dynamic> map);

  /// This method is meant to be overriden when the service includes a custom
  /// error handler. By default, that functionality is not required and a
  /// normal server error is generated.
  bool serviceErrorHandler(Response response, U handler) {
    return false;
  }
}

enum ResponseHandlerResult {
  invalidRequest,
  unexpectedContent,
  serverError,
  invalidSession,
  onMaintenanceWindow,
  restApiError
}

abstract class BaseServiceResponseHandler {
  void onInvalidRequest(Error error);

  void onUnexpectedContent(Exception exception);

  void onServerError();

  void onInvalidSession();

  void onMaintenanceWindow(Map<String, dynamic> map);

  void restApiError(Response response);
}
