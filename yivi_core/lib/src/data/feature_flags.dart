enum FeatureFlag {
  onboardingV2(
    "A",
    "Onboarding: one intro page, terms, empty tab with two routes, Android install referrer",
  ),
  emailLinking(
    "B",
    "E-mail: skipped in onboarding, home banner, code or link, share with MijnYivi",
  ),
  dataTabV2("C", "Your data: demo/staging apart, expired state"),
  dataTabCategories(
    "C+",
    "Your data: categories, favourites, collapsible sections",
  ),
  externalIssuerFlow(
    "E",
    "Data from another website: heads-up and waiting state",
  ),
  formFieldsV2("H", "Form fields: white fields with the label inside"),
  calmSuccess("J", "Success screens: calm illustrations"),
  shareScreenV2("K", "Sharing: Gewaarmerkt door, trust bar, extra check");

  const FeatureFlag(this.id, this.description);

  final String id;
  final String description;

  String get prefKey => "preference.feature_flag.$name";
}
