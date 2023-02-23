
import 'package:palspace_backend/helpers/login/session.helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class PostsRouter {
  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final session = await LoginSession_.fromRequest(request);
      final user = session.user.value;


    });

    return router;
  }
}