import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:palspace_backend/utilities/request_body.dart';
import 'package:shelf/shelf.dart';

part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
class UserDetailsRequest with _$UserDetailsRequest implements RequestBody {
  const factory UserDetailsRequest(
      {required String? bio,
      required String? currentCity,
      required String? homeCity}) = _UserDetailsRequest;

  factory UserDetailsRequest.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsRequestFromJson(json);
}
