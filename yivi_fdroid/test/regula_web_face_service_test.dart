import "package:flutter_test/flutter_test.dart";
import "package:yivi/face_liveness_message.dart";
import "package:yivi/regula_web_face_service.dart";
import "package:yivi_core/yivi_core.dart";

void main() {
  group("faceCaptureMessageFrom", () {
    test("PROCESS_FINISHED, liveness confirmed → live result with id", () {
      final message = faceCaptureMessageFrom(
        '{"status":"passed","transactionId":"txn-1","isLive":true}',
      );
      expect(message.failure, isNull);
      expect(message.result!.isLive, isTrue);
      expect(message.result!.transactionId, "txn-1");
    });

    test("PROCESS_FINISHED, liveness not confirmed → id still forwarded", () {
      final message = faceCaptureMessageFrom(
        '{"status":"failed","transactionId":"txn-2"}',
      );
      expect(message.failure, isNull);
      expect(message.result!.isLive, isFalse);
      // A failed liveness still forwards the id so the issuer decides.
      expect(message.result!.transactionId, "txn-2");
    });

    test("PROCESS_FINISHED, no transaction id → null id (fail-open)", () {
      final message = faceCaptureMessageFrom('{"status":"passed"}');
      expect(message.failure, isNull);
      expect(message.result!.isLive, isTrue);
      expect(message.result!.transactionId, isNull);
    });

    test("an empty transaction id is treated as no id", () {
      final message = faceCaptureMessageFrom(
        '{"status":"passed","transactionId":""}',
      );
      expect(message.result!.transactionId, isNull);
    });

    test("cancelled → abort", () {
      final message = faceCaptureMessageFrom('{"status":"cancelled"}');
      expect(message.result, isNull);
      expect(message.failure, "cancelled");
    });

    test("error → abort with the reported message", () {
      final message = faceCaptureMessageFrom(
        '{"status":"error","message":"camera denied"}',
      );
      expect(message.result, isNull);
      expect(message.failure, contains("camera denied"));
    });

    test("malformed JSON → abort, does not throw", () {
      final message = faceCaptureMessageFrom("not json");
      expect(message.result, isNull);
      expect(message.failure, isNotNull);
    });

    test("unknown status → abort", () {
      final message = faceCaptureMessageFrom('{"status":"weird"}');
      expect(message.result, isNull);
      expect(message.failure, contains("weird"));
    });
  });

  group("RegulaWebFaceService.captureLiveness", () {
    test("appends the language code to the capture URL", () async {
      late Uri presented;
      final service = RegulaWebFaceService(
        captureUrl: Uri.parse("https://faceapi.example/capture"),
        present: (url) async {
          presented = url;
          return const FaceCaptureMessage.completed(
            RegulaLivenessResult(isLive: true, transactionId: "t"),
          );
        },
      );

      await service.captureLiveness(languageCode: "nl");

      expect(presented.queryParameters["lang"], "nl");
    });

    test("defaults the language to 'en' when none is given", () async {
      late Uri presented;
      final service = RegulaWebFaceService(
        captureUrl: Uri.parse("https://faceapi.example/capture"),
        present: (url) async {
          presented = url;
          return const FaceCaptureMessage.completed(
            RegulaLivenessResult(isLive: true, transactionId: "t"),
          );
        },
      );

      await service.captureLiveness();

      expect(presented.queryParameters["lang"], "en");
    });

    test("returns the completed result", () async {
      final service = RegulaWebFaceService(
        present: (_) async => const FaceCaptureMessage.completed(
          RegulaLivenessResult(isLive: true, transactionId: "txn-ok"),
        ),
      );

      final result = await service.captureLiveness();

      expect(result.isLive, isTrue);
      expect(result.transactionId, "txn-ok");
    });

    test("throws when the session is aborted", () async {
      final service = RegulaWebFaceService(
        present: (_) async => const FaceCaptureMessage.aborted("cancelled"),
      );

      expect(service.captureLiveness(), throwsStateError);
    });

    test("throws when the route is dismissed without a result", () async {
      final service = RegulaWebFaceService(present: (_) async => null);

      expect(service.captureLiveness(), throwsStateError);
    });
  });
}
