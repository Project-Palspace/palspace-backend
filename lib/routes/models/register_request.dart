import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:palspace_backend/utilities/request_body.dart';
import 'package:shelf/shelf.dart';

part 'register_request.freezed.dart';
part 'register_request.g.dart';

@freezed
class RegisterRequest with _$RegisterRequest implements RequestBody {
  const factory RegisterRequest({
    required String email,
    required String password,
    required String username,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}
