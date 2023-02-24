import 'dart:io';

import 'package:shelf/shelf.dart';

Middleware loggingHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      final ipAddress =
          ((request.context['shelf.io.connection_info'] as HttpConnectionInfo)
              .remoteAddress
              .address);
      print(
          "[${DateTime.now().toIso8601String()}] [${request.method}] From: $ipAddress Uri: ${request.requestedUri} ");
      //TODO: Log actual things?
      //TODO: Rate limiting?
      return response;
    };
  };
}
