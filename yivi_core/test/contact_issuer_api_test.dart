import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:yivi_core/src/data/contact_issuer_api.dart";

/// The issuer's verify answer and the IRMA server's session pointer.
http.Response _route(http.Request request, {required http.Response issuer}) {
  if (request.url.path == "/irma/session") {
    expect(request.body, "the-jwt");
    return http.Response(
      jsonEncode({
        "sessionPtr": {"u": "https://irma.example/s/1", "irmaqr": "issuing"},
      }),
      200,
    );
  }
  return issuer;
}

final _verified = http.Response(
  jsonEncode({
    "jwt": "the-jwt",
    "irma_server_url": "https://irma.example/irma",
  }),
  200,
);

/// What the e-mail and SMS issuers say, in their own formats, and the session
/// a right code starts.
void main() {
  group("e-mail", () {
    final api = EmailIssuerApi(host: "https://mail.example");

    Future<T> run<T>(
      Future<T> Function() body,
      http.Response Function(http.Request) answer,
    ) => http.runWithClient(body, () => MockClient((r) async => answer(r)));

    test("send posts the address and the language", () async {
      late http.Request sent;
      await run(() => api.send(target: "ann@example.com", language: "nl"), (r) {
        sent = r;
        return http.Response("", 200);
      });
      expect(sent.url.toString(), "https://mail.example/api/embedded/send");
      expect(jsonDecode(sent.body), {
        "email": "ann@example.com",
        "language": "nl",
      });
    });

    for (final (error, type) in [
      ("error_invalid_token", ContactWrongCode),
      ("error_ratelimit", ContactRateLimited),
      ("error_other", ContactServerError),
    ]) {
      test("$error on send and verify", () async {
        final answer = http.Response(jsonEncode({"error": error}), 400);
        await expectLater(
          run(() => api.send(target: "a@b.c", language: "en"), (_) => answer),
          throwsA(isA<Object>().having((e) => e.runtimeType, "type", type)),
        );
        await expectLater(
          run(() => api.verify(target: "a@b.c", code: "ABC123"), (_) => answer),
          throwsA(isA<Object>().having((e) => e.runtimeType, "type", type)),
        );
      });
    }

    test("verify posts the address and code, then starts the session to "
        "continue here", () async {
      late http.Request verify;
      final pointer = await run(
        () => api.verify(target: "ann@example.com", code: "X1"),
        (r) {
          if (r.url.path == "/api/embedded/verify") verify = r;
          return _route(r, issuer: _verified);
        },
      );
      expect(jsonDecode(verify.body), {
        "email": "ann@example.com",
        "token": "X1",
      });
      expect(pointer.u, "https://irma.example/s/1");
      expect(pointer.continueOnSecondDevice, isTrue);
    });

    test("the IRMA server says no: verify fails", () async {
      await expectLater(
        run(
          () => api.verify(target: "a@b.c", code: "X1"),
          (r) => r.url.path == "/irma/session"
              ? http.Response("no", 500)
              : _verified,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group("SMS", () {
    SmsIssuerApi api(http.Response Function(http.Request) answer) =>
        SmsIssuerApi(
          host: "https://sms.example",
          client: MockClient((r) async => answer(r)),
        );

    for (final (body, type) in [
      ("error:cannot-validate-token", ContactWrongCode),
      ("error:ratelimit", ContactRateLimited),
      ("error:other", ContactServerError),
    ]) {
      test("$body on verify", () async {
        await expectLater(
          api(
            (_) => http.Response(body, 400),
          ).verify(target: "+31612345678", code: "123456"),
          throwsA(isA<Object>().having((e) => e.runtimeType, "type", type)),
        );
      });
    }

    test("verify posts the number and code, then starts the session to "
        "continue here", () async {
      late http.Request verify;
      final pointer = await api((r) {
        if (r.url.path == "/api/embedded/verify") verify = r;
        return _route(r, issuer: _verified);
      }).verify(target: "+31612345678", code: "123456");
      expect(jsonDecode(verify.body), {
        "phone": "+31612345678",
        "token": "123456",
      });
      expect(pointer.irmaqr, "issuing");
      expect(pointer.continueOnSecondDevice, isTrue);
    });
  });
}
