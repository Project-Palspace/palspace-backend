import 'dart:convert';

import 'package:palspace_backend/routes/models/login_request.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/routes/models/user_details.dart';
import 'package:palspace_backend/routes/models/user_facts_request.dart';
import 'package:shelf/shelf.dart';

class RequestBody {
  static Future<T> fromRequest<T extends RequestBody>(Request request) async {
    final content = await request.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final type = T;
    final deserializer = _deserializers[type];
    if (deserializer == null) {
      throw ArgumentError(
          'Unsupported type parameter for fromRequest: $type. Supported types are: ${_deserializers.keys}');
    }
    try {
      return deserializer(json) as T;
    } catch (e) {
      throw FormatException('Failed to deserialize request body: $e');
    }
  }

  static final _deserializers = {
    LoginRequest: (json) => LoginRequest.fromJson(json),
    RegisterRequest: (json) => RegisterRequest.fromJson(json),
    UserFactsRequest: (json) => UserFactsRequest.fromJson(json),
    UserDetailsRequest: (json) => UserDetailsRequest.fromJson(json),
  };
}
