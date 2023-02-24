import 'package:shelf/shelf.dart';

Middleware badRequestHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      if (response.statusCode == 400) {
        final body = await response.readAsString();
        final jsonResponse = body;

        if (body.isNotEmpty) {
          return Response.notFound(jsonResponse,
              headers: {'Content-Type': 'application/json'});
        } else {
          return Response(400);
        }
      }
      return response;
    };
  };
}
