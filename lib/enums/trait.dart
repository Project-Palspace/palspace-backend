enum Trait { EMAIL_VERIFIED, ACCOUNT_DETAILS_LOCKED, SUSPENDED }

extension TraitEx on Trait {
  String get name => toString().split('.').last;
}
