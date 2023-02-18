import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
class UserDetailsRequest with _$UserDetailsRequest {
  const factory UserDetailsRequest({required String? bio, required String? currentCity, required String? homeCity}) = _UserDetailsRequest;

  factory UserDetailsRequest.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsRequestFromJson(json);
}
