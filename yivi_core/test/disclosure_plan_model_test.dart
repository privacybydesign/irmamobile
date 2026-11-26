import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/screens/session/models/disclosure_plan_view.dart";

/// A plan as irmago sends it: a required choice with one slot of two cards
/// (one expired), and an optional choice that can be skipped.
const _planJson = """
{
  "choices": [
    {"optional": false, "options": [{"slots": [{
      "id": "email", "multiple": false,
      "candidates": [
        {"credential_id": "pbdf.sidn-pbdf.email", "hash": "e-1", "name": "E-mail",
         "issuer": {"id": "pbdf.sidn-pbdf", "name": "SIDN", "verified": true},
         "format": "idemix", "revoked": false, "revocation_supported": false,
         "attributes": [{"claim_path": ["email"], "display_name": "E-mail",
           "value": {"type": "string", "string": "a@a.nl"},
           "requested_values": [{"type": "string", "string": "a@a.nl"}, {"type": "string", "string": "b@b.nl"}]}],
         "usable": true, "unusable_reason": ""},
        {"credential_id": "pbdf.sidn-pbdf.email", "hash": "e-2", "name": "E-mail",
         "issuer": {"id": "pbdf.sidn-pbdf", "name": "SIDN", "verified": true},
         "format": "idemix", "revoked": false, "revocation_supported": false,
         "attributes": [{"claim_path": ["email"], "display_name": "E-mail",
           "value": {"type": "string", "string": "old@a.nl"}}],
         "usable": false, "unusable_reason": "expired"}
      ],
      "obtainable": []
    }]}]},
    {"optional": true, "options": [{"slots": [{
      "id": "phone", "multiple": false, "candidates": [], "obtainable": []
    }]}]}
  ],
  "issued_credential_ids": {},
  "wrong_credential_issued": null
}
""";

void main() {
  final plan = DisclosurePlan.fromJson(
    jsonDecode(_planJson) as Map<String, dynamic>,
  );

  test("decodes choices, options, slots and candidates", () {
    expect(plan.choices, hasLength(2));
    final slot = plan.choices.first.options.single.slots.single;
    expect(slot.id, "email");
    expect(slot.candidates.map((c) => c.hash), ["e-1", "e-2"]);
    expect(slot.candidates.first.usable, isTrue);
    expect(slot.candidates.first.unusableReason, isNull);
    expect(slot.candidates.last.usable, isFalse);
    expect(slot.candidates.last.unusableReason, UnusableReason.expired);
    expect(
      slot.candidates.first.attributes.single.requestedValues.map(
        (v) => v.string,
      ),
      ["a@a.nl", "b@b.nl"],
    );
    expect(plan.choices.last.optional, isTrue);
  });

  test("the default answer: the usable card, nothing for the optional "
      "choice", () {
    expect(canShare(plan), isTrue);
    final answer = answerFor(plan, const DisclosureSelection());
    expect(
      jsonEncode(answer),
      jsonEncode([
        {
          "option": 0,
          "slots": [
            {
              "slot_id": "email",
              "credentials": [
                {
                  "credential_id": "pbdf.sidn-pbdf.email",
                  "credential_hash": "e-1",
                  "attribute_paths": [
                    ["email"],
                  ],
                },
              ],
            },
          ],
        },
        {"option": -1, "slots": []},
      ]),
    );
    expect(usedCards(plan, const DisclosureSelection()).map((c) => c.hash), [
      "e-1",
    ]);
  });

  test("an unusable card is never chosen, also when picked", () {
    final picked = const DisclosureSelection().withCards("email", ["e-2"]);
    final slot = plan.choices.first.options.single.slots.single;
    expect(chosenCards(slot, picked).map((c) => c.hash), ["e-1"]);
  });

  test("the permission is sent per slot", () {
    final event = SessionUserInteractionEvent.permission(
      sessionId: 3,
      granted: true,
      choices: [ChoiceSelection.none()],
    );
    expect(event.toJson()["type"], "permission");
    expect(
      jsonEncode(event.payload),
      '{"granted":true,"choices":[{"option":-1,"slots":[]}]}',
    );
  });

  test("continuing a chained session", () {
    final event = SessionUserInteractionEvent.continueNextSession(sessionId: 3);
    expect(event.toJson()["type"], "continue_next_session");
    expect(event.payload, isNull);
  });
}
