import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/return_url.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/screens/session/models/session_outcome.dart";

SessionFacts _facts({
  SessionType type = SessionType.disclosure,
  String? returnUrl,
  SessionPlatform platform = SessionPlatform.android,
  bool secondDevice = false,
  bool inAppLaunched = false,
  bool forRequest = false,
  bool keyshareLink = false,
}) => SessionFacts(
  type: type,
  returnUrl: ReturnURL.parse(returnUrl),
  platform: platform,
  secondDevice: secondDevice,
  inAppLaunched: inAppLaunched,
  forRequest: forRequest,
  keyshareLink: keyshareLink,
);

const _web = "https://www.shop.example/done";
const _inApp = "https://shop.example/done?inapp=true";
const _tel = "tel:+31201234567";

void main() {
  group("after success", () {
    for (final platform in SessionPlatform.values) {
      group(platform.name, () {
        SessionOutcome of({
          SessionType type = SessionType.disclosure,
          String? returnUrl,
          bool secondDevice = false,
          bool inAppLaunched = false,
          bool forRequest = false,
          bool keyshareLink = false,
        }) => sessionOutcomeOf(
          _facts(
            type: type,
            returnUrl: returnUrl,
            platform: platform,
            secondDevice: secondDevice,
            inAppLaunched: inAppLaunched,
            forRequest: forRequest,
            keyshareLink: keyshareLink,
          ),
        );

        test("the e-mail linking disclosure comes first", () {
          expect(
            of(
              keyshareLink: true,
              returnUrl: _tel,
              secondDevice: true,
              inAppLaunched: true,
              forRequest: true,
            ),
            isA<EmailLinked>(),
          );
        });

        test("an issuance for a request: back to the request", () {
          expect(
            of(
              type: SessionType.issuance,
              forRequest: true,
              returnUrl: _web,
              inAppLaunched: true,
            ),
            isA<AddedForRequest>(),
          );
        });

        test("a disclosure for a request is not one", () {
          expect(of(forRequest: true), isNot(isA<AddedForRequest>()));
        });

        test("launched from the app: added, the card flies home", () {
          expect(
            of(
              type: SessionType.issuance,
              inAppLaunched: true,
              returnUrl: _tel,
              secondDevice: true,
            ),
            isA<Added>(),
          );
        });

        test("a tel: return URL calls, on either device", () {
          for (final second in [false, true]) {
            for (final type in SessionType.values) {
              final outcome = of(
                type: type,
                returnUrl: _tel,
                secondDevice: second,
              );
              expect(outcome, isA<CallVia>());
              expect((outcome as CallVia).url.toString(), _tel);
            }
          }
        });

        test("second device: an issuance is added, the rest shared on the "
            "other device; the return URL is not opened", () {
          expect(
            of(type: SessionType.issuance, secondDevice: true, returnUrl: _web),
            isA<Added>(),
          );
          for (final type in [SessionType.disclosure, SessionType.signature]) {
            final outcome = of(type: type, secondDevice: true, returnUrl: _web);
            expect((outcome as Shared).next, isA<OtherDevice>());
          }
        });

        test("same device with a return URL: shared, back to its host", () {
          for (final type in [SessionType.disclosure, SessionType.signature]) {
            final next = (of(type: type, returnUrl: _web) as Shared).next;
            expect(next, isA<ReturnTo>());
            expect((next as ReturnTo).host, "shop.example");
            expect(next.url.toString(), _web);
          }
          final inApp = (of(returnUrl: _inApp) as Shared).next as ReturnTo;
          expect(inApp.url.isInApp, isTrue);
        });

        test("same device with a return URL: an issuance opens it", () {
          final outcome = of(type: SessionType.issuance, returnUrl: _web);
          expect(outcome, isA<OpenReturnUrl>());
          expect((outcome as OpenReturnUrl).url.toString(), _web);
        });

        test("same device without a return URL", () {
          final ios = platform == SessionPlatform.ios;
          for (final type in [SessionType.disclosure, SessionType.signature]) {
            final next = (of(type: type) as Shared).next;
            expect(next, ios ? isA<GoBackYourself>() : isA<BackToWebsite>());
          }
          expect(
            of(type: SessionType.issuance),
            ios ? isA<IssuedArrowBack>() : isA<IssuedToBackground>(),
          );
        });
      });
    }
  });

  group("closing", () {
    for (final platform in SessionPlatform.values) {
      group(platform.name, () {
        final caller = platform == SessionPlatform.ios
            ? CallerReturn.arrowBack
            : CallerReturn.background;

        ({ReturnURL? reopen, CallerReturn caller}) close({
          SessionType type = SessionType.disclosure,
          String? returnUrl,
          bool secondDevice = false,
          bool inAppLaunched = false,
          bool forRequest = false,
          String? errorType,
        }) => sessionCloseOf(
          _facts(
            type: type,
            returnUrl: returnUrl,
            platform: platform,
            secondDevice: secondDevice,
            inAppLaunched: inAppLaunched,
            forRequest: forRequest,
          ),
          error: errorType == null
              ? null
              : SessionError(errorType: errorType, info: ""),
        );

        test("a return URL is reopened, nothing else", () {
          for (final url in [_web, _inApp]) {
            final c = close(returnUrl: url, errorType: "transport");
            expect(c.reopen.toString(), url);
            expect(c.caller, CallerReturn.none);
          }
        });

        test("not reopened: tel:, second device, after the return URL "
            "failed, or launched from the app", () {
          expect(close(returnUrl: _tel).reopen, isNull);
          expect(close(returnUrl: _web, secondDevice: true).reopen, isNull);
          expect(
            close(returnUrl: _web, errorType: "clientReturnUrl").reopen,
            isNull,
          );
          expect(close(returnUrl: _web, inAppLaunched: true).reopen, isNull);
          for (final c in [
            close(returnUrl: _tel),
            close(returnUrl: _web, secondDevice: true),
            close(returnUrl: _web, errorType: "clientReturnUrl"),
            close(returnUrl: _web, inAppLaunched: true),
          ]) {
            expect(c.caller, CallerReturn.none);
          }
        });

        test("no return URL: back to the caller", () {
          for (final type in SessionType.values) {
            final c = close(type: type, errorType: "transport");
            expect(c.reopen, isNull);
            expect(c.caller, caller);
          }
        });

        test("no return URL, but for a request, on a second device or "
            "launched from the app: just closes", () {
          expect(close(forRequest: true).caller, CallerReturn.none);
          expect(close(secondDevice: true).caller, CallerReturn.none);
          expect(close(inAppLaunched: true).caller, CallerReturn.none);
        });
      });
    }
  });
}
