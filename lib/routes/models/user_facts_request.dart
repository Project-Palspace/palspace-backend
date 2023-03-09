import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:palspace_backend/utilities/request_body.dart';
import 'package:shelf/src/request.dart';

part 'user_facts_request.freezed.dart';
part 'user_facts_request.g.dart';

@freezed
class UserFactsRequest with _$UserFactsRequest implements RequestBody {
  const factory UserFactsRequest(
      {required String? firstName,
        required String? lastName,
        required String? nationality,
        required DateTime? birthDate}) = _UserDetailsRequest;

  factory UserFactsRequest.fromJson(Map<String, dynamic> json) =>
      _$UserFactsRequestFromJson(json);
}
