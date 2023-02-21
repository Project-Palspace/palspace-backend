enum VerifyReason { EMAIL_VERIFY, DELETE_VERIFY }

extension VerifyReasonEx on VerifyReason {
  String get name => toString().split('.').last;
}
