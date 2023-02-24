import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';

part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
class UserDetailsRequest with _$UserDetailsRequest {
  const factory UserDetailsRequest(
      {required String? bio,
      required String? currentCity,
      required String? homeCity}) = _UserDetailsRequest;

  factory UserDetailsRequest.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsRequestFromJson(json);

  //TODO: Can we instead extend the class from a general RequestBody class with this function in it?
  static Future<UserDetailsRequest> fromRequest(Request request) async =>
      RequestUtils.bodyFromRequest<UserDetailsRequest>(request);
}
