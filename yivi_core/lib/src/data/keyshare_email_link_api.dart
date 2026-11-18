import "dart:convert";
import "dart:io" show HttpStatus;

import "package:http/http.dart" as http;

import "../models/session.dart";

abstract class KeyshareEmailLinkApi {
  /// Starts the disclosure session in which the user shares the issued e-mail
  /// address with MijnYivi, so the keyshare server can link it to this app.
  Future<SessionPointer> startSession();
}

class KeyshareEmailLinkUnavailable implements Exception {
  @override
  String toString() => "The keyshare e-mail link endpoint is not configured";
}

class DefaultKeyshareEmailLinkApi implements KeyshareEmailLinkApi {
  final String url;

  DefaultKeyshareEmailLinkApi({required this.url});

  @override
  Future<SessionPointer> startSession() async {
    if (url.isEmpty) throw KeyshareEmailLinkUnavailable();

    final response = await http.post(Uri.parse(url));
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        "Starting the e-mail link failed: ${response.statusCode} ${response.body}",
      );
    }

    return SessionPointer.fromJson(
      jsonDecode(response.body)["sessionPtr"],
    ).copyWith(continueOnSecondDevice: true);
  }
}
