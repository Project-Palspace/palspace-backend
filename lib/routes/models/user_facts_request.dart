import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';

part 'user_facts_request.freezed.dart';
part 'user_facts_request.g.dart';

@freezed
class UserFactsRequest with _$UserFactsRequest {
  const factory UserFactsRequest(
      {required String? firstName,
      required String? lastName,
      required String? nationality,
      required DateTime? birthDate}) = _UserDetailsRequest;

  factory UserFactsRequest.fromJson(Map<String, dynamic> json) =>
      _$UserFactsRequestFromJson(json);

  //TODO: Can we instead extend the class from a general RequestBody class with this function in it?
  static Future<UserFactsRequest> fromRequest(Request request) async =>
      RequestUtils.bodyFromRequest<UserFactsRequest>(request);
}
