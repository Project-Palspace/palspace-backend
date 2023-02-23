
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/helpers/user/user.helpers.dart';
import 'package:palspace_backend/helpers/user/user.trait-helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class PostsRouter {
  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final user = await User_.fromRequest(request);

       if (user.hasTrait(Trait.SUSPENDED)) {

       }

    });

    return router;
  }
}