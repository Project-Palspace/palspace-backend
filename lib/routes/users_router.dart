import 'dart:convert';

import 'package:palspace_backend/exceptions/email_taken_exception.dart';
import 'package:palspace_backend/exceptions/email_validation_exception.dart';
import 'package:palspace_backend/exceptions/password_validation_exception.dart';
import 'package:palspace_backend/exceptions/username_taken_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/routes/models/login_request.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/request_body.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UsersRouter {
  ServiceCollection serviceCollection;

  UsersRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.post('/login', (Request request) async {
      final body = await RequestBody.fromRequest<LoginRequest>(request);
      final session = await LoginSession.fromLoginRequest(body, serviceCollection);

      if (session == null) {
        return Response(401, body: 'Invalid credentials');
      }

      return Response(200, body: json.encode(session.toJson()), headers: {'Content-Type': 'application/json'});
    });

    router.post('/register', (Request request) async {
      final body = await RequestBody.fromRequest<RegisterRequest>(request);

      try
      {
        final session = await User.fromRegisterRequest(body, serviceCollection);
        return Response(201, body: json.encode(session.toJson()), headers: {'Content-Type': 'application/json'});
      }
      on EmailTakenException catch (e) {
        return Response(409, body: e.message);
      }
      on EmailValidationException catch (e) {
        return Response(400, body: e.message);
      }
      on UsernameTakenException catch (e) {
        return Response(409, body: e.message);
      }
      on PasswordValidationException catch (e) {
        return Response(409, body: e.message);
      }
    });

    return router;
  }
}
