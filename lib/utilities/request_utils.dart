import 'dart:convert';

import 'package:palspace_backend/routes/models/login_request.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/routes/models/user_details.dart';
import 'package:palspace_backend/routes/models/user_facts_request.dart';
import 'package:shelf/shelf.dart';

@Deprecated('To be replaced with RequestBody class for request models!')
class RequestUtils {
  static Future<T> bodyFromRequest<T>(Request request) async {
    final content = await request.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final body = getBodyFromJson<T>(json);
    return body;
  }

  static T getBodyFromJson<T>(Map<String, dynamic> json) {
    if (T == LoginRequest) {
      return LoginRequest.fromJson(json) as T;
    } else if (T == RegisterRequest) {
      return RegisterRequest.fromJson(json) as T;
    } else if (T == UserFactsRequest) {
      return UserFactsRequest.fromJson(json) as T;
    } else if (T == UserDetailsRequest) {
      return UserDetailsRequest.fromJson(json) as T;
    } else {
      throw Exception(
          'Invalid type parameter for fromRequest, must be $T but no such type exists in the function');
    }
  }
}
