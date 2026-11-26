import "package:flutter/widgets.dart";

/// The keys of the disclosure screens, in one place: the integration tests
/// find the screens by them.
abstract final class DisclosureKeys {
  // The overview.
  static const overview = Key("share_overview");
  static const values = Key("share_values");
  static Key value(String name) => Key("share_value_$name");
  static const pile = Key("share_pile");
  static const change = Key("share_change");
  static const optionalHint = Key("share_optional_hint");
  static Key optionalCard(int choice) => Key("share_optional_card_$choice");
  static const keepCard = Key("share_keep_card");
  static const lead = Key("share_lead");
  static const title = Key("share_title");
  static Key offered(int n) => Key("share_offered_card_$n");

  // The bottom bar.
  static const button = Key("share_button");
  static const reason = Key("share_reason");
  static const trustWash = Key("share_trust_wash");
  static const message = Key("share_message");
  static const anywayDialog = Key("share_anyway_dialog");
  static const anywayCancel = Key("share_anyway_cancel");
  static const anywayConfirm = Key("share_anyway_confirm");
  static const scrollView = Key("share_scroll_view");
  static const panel = Key("share_panel");
}
