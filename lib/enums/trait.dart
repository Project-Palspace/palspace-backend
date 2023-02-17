enum Trait { EMAIL_VERIFIED }

extension TraitEx on Trait {
  String get name => toString().split('.').last;
}
