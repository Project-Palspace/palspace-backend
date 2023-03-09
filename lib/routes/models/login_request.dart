import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:palspace_backend/utilities/request_body.dart';
import 'package:shelf/shelf.dart';

part 'login_request.freezed.dart';
part 'login_request.g.dart';

@freezed
class LoginRequest with _$LoginRequest implements RequestBody {
  const factory LoginRequest(
      {required String? email, required String? password}) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}
