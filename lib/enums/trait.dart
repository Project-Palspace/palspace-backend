enum Trait {
  EMAIL_VERIFIED,
  ACCOUNT_FACTS_LOCKED,
  ACCOUNT_FACTS_FILLED,
  SUSPENDED
}

extension TraitEx on Trait {
  String get name => toString().split('.').last;
}
