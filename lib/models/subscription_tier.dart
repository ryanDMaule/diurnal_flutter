enum SubscriptionTier {
  free,
  pro;

  bool get isPro => this == SubscriptionTier.pro;
}
