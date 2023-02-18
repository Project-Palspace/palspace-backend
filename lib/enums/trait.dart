enum Trait { EMAIL_VERIFIED, ACCOUNT_DETAILS_LOCKED }

extension TraitEx on Trait {
  String get name => toString().split('.').last;
}
