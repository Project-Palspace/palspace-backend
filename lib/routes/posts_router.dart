
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class PostsRouter {
  Router get router {
    final router = Router();

    router.get('/', (Request request) async {

    });

    return router;
  }
}