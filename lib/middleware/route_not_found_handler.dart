import 'dart:convert';
import 'package:shelf/shelf.dart';

Middleware routeNotFoundHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      if (response.statusCode == 404) {
        final body = await response.readAsString();
        final jsonResponse = {'error': body};

        if (body.isNotEmpty) {
          return Response.notFound(jsonEncode(jsonResponse),
              headers: {'Content-Type': 'application/json'});
        } else {
          return Response(404);
        }
      }
      return response;
    };
  };
}
