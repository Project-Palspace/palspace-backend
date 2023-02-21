
import 'package:dotenv/dotenv.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/middleware/authentication.dart';
import 'package:palspace_backend/middleware/route_not_found_handler.dart';
import 'package:palspace_backend/routes/debug_router.dart';
import 'package:palspace_backend/routes/user_details_router.dart';
import 'package:palspace_backend/routes/user_facts_router.dart';
import 'package:palspace_backend/routes/user_management_router.dart';
import 'package:palspace_backend/routes/user_router.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class ApiService {
  ServiceCollection serviceCollection;

  ApiService(this.serviceCollection);

  Future startApi() async {
    final app = Router();
    final pipeline = Pipeline()
        .addMiddleware(routeNotFoundHandler())
        .addHandler(app.call);

    final dotEnv = serviceCollection.get<DotEnv>();

    app.mount('/user/', UserRouter(serviceCollection).router);
    app.mount(
        '/user/manage',
        await authenticatedRouter(
            UserManagementRouter(serviceCollection).router,
            requiredTraits: [Trait.EMAIL_VERIFIED]));
    app.mount(
        '/user/details',
        await authenticatedRouter(
            UserDetailsRouter(serviceCollection).router,
            requiredTraits: [Trait.EMAIL_VERIFIED]));
    app.mount(
        '/user/facts',
        await authenticatedRouter(
            UserFactsRouter(serviceCollection).router,
            requiredTraits: [Trait.EMAIL_VERIFIED]));
    app.mount('/debug/',
        await authenticatedRouter(DebugRouter(serviceCollection).router));
    app.mount('/debug-noauth/', DebugRouter(serviceCollection).router);

    final server = await io.serve(
        pipeline, dotEnv['HTTP_HOST']!, int.parse(dotEnv['HTTP_PORT']!));
    print('Server listening on http://${server.address.host}:${server.port}');
  }

  authenticatedRouter(Router router,
          {List<Trait> requiredTraits = const [], List<Trait> requiredMissingTraits = const [ Trait.SUSPENDED]}) async =>
      Pipeline()
          .addMiddleware(await authenticateMiddleware(serviceCollection,
              requiredTraits: requiredTraits, requiredMissingTraits: requiredMissingTraits))
          .addHandler(router);
}

class AuthenticatedUsersRouter {}
