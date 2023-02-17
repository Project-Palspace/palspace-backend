import 'package:palspace_backend/enums/trait.dart';
import 'package:shelf/shelf.dart';

class MissingTraitException {
  final Trait trait;
  late final Response response;

  MissingTraitException(this.trait) {
    response =
        Response(403, body: "missing-${trait.toString().toLowerCase()}");
  }
}
