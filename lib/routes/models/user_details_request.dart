import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_details_request.freezed.dart';
part 'user_details_request.g.dart';

@freezed
class UserDetailsRequest with _$UserDetailsRequest {
  const factory UserDetailsRequest({required String? firstName,
      required String? lastName,
      required String? homeCity,
      required String? currentCity,
      required DateTime? birthDate,
      required String? bio}) = _UserDetailsRequest;

  factory UserDetailsRequest.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsRequestFromJson(json);
}
