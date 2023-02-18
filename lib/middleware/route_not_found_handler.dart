import 'dart:convert';
import 'package:shelf/shelf.dart';

Middleware routeNotFoundHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      if (response.statusCode == 404) {
        final jsonResponse = {'error': await response.readAsString()};
        return Response.notFound(jsonEncode(jsonResponse), headers: {'Content-Type': 'application/json'});
      }
      return response;
    };
  };
}
