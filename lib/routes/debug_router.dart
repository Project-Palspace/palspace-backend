import 'package:palspace_backend/services/service_collection.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class DebugRouter {
  ServiceCollection serviceCollection;

  DebugRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.get('/', (Request request) {
      return Response.ok('spank me daddy');
    });

    return router;
  }
}
