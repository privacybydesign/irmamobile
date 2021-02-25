import 'dart:convert';

import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

class MissingSessionPointer implements Exception {
  String errorMessage() {
    return 'URI does not contain a sessionpointer';
  }
}

@JsonSerializable()
class SessionPointer {
  SessionPointer({this.u, this.irmaqr, this.continueOnSecondDevice = false, this.returnURL, this.wizard});

  @JsonKey(name: 'u')
  String u;

  @JsonKey(name: 'irmaqr')
  String irmaqr;

  @JsonKey(name: 'wizard')
  String wizard;

  // Whether the session should be continued on the mobile device,
  // or on the device which has displayed a QR code
  @JsonKey(name: 'continueOnSecondDevice', defaultValue: false)
  bool continueOnSecondDevice;

  @Deprecated("This parameter is deprecated and will be removed at the end of 2020. Use clientReturnURL instead.")
  @JsonKey(name: 'returnURL')
  String returnURL;

  Future<void> validate() async {
    if (wizard == null) return;

    final repo = IrmaRepository.get();

    if (await repo.getIssueWizardActive().first) {
      throw UnsupportedError("cannot start wizard within a wizard");
    }

    final irmaConfig = await repo.getIrmaConfiguration().first;
    final devMode = await repo.getDeveloperMode().first;
    final scheme = wizard.contains(".") ? wizard.split(".").first : null;

    if (!irmaConfig.issueWizards.containsKey(wizard) || !irmaConfig.requestorSchemes.containsKey(scheme)) {
      throw ArgumentError.value(wizard, "wizard");
    }

    final demoScheme = irmaConfig.requestorSchemes[scheme].demo;
    if (!devMode && demoScheme) {
      throw UnsupportedError("cannot start wizard from demo scheme: developer mode not enabled");
    }

    final wizardData = irmaConfig.issueWizards[wizard];
    if (u == null || demoScheme || wizardData.allowOtherRequestors) {
      return;
    }
    final host = Uri.parse(u).host;
    final requestor = irmaConfig.requestors[host];
    if (requestor == null) {
      throw UnsupportedError("cannot start wizard: unknown requestor");
    }
    if (wizardData.id.split(".").getRange(0, 2).join(".") != requestor.id) {
      throw UnsupportedError("cannot start wizard not belonging to session requestor");
    }
  }

  factory SessionPointer.fromString(String content) {
    // Use lookahead and lookbehinds to block out the non-JSON part of the string
    final regexps = [
      RegExp("(?<=^irma:\/\/qr\/json\/).*"),
      RegExp("(?<=^cardemu:\/\/qr\/json\/).*"),
      RegExp("(?<=^intent:\/\/qr\/json\/).*(?=#)"),
      RegExp("(?<=^https:\/\/irma\.app\/-\/session#).*"),
      RegExp("(?<=^https:\/\/irma\.app\/-pilot\/session#).*"),
      RegExp(".*", multiLine: true, dotAll: true),
    ];

    try {
      String jsonString;
      for (final regex in regexps) {
        final String match = regex.stringMatch(content);
        if (match != null && match.isNotEmpty) {
          jsonString = Uri.decodeComponent(match);
          break;
        }
      }

      if (jsonString == null) {
        throw MissingSessionPointer();
      }

      return SessionPointer.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      throw MissingSessionPointer();
    }
  }

  factory SessionPointer.fromJson(Map<String, dynamic> json) => _$SessionPointerFromJson(json);
  Map<String, dynamic> toJson() => _$SessionPointerToJson(this);
}

@JsonSerializable()
class SessionError {
  SessionError({
    this.errorType,
    this.wrappedError,
    this.info,
    this.stack,
    this.remoteStatus,
    this.remoteError,
  });

  @JsonKey(name: 'ErrorType')
  String errorType;

  @JsonKey(name: 'WrappedError')
  String wrappedError;

  @JsonKey(name: 'Info')
  String info;

  @JsonKey(name: 'Stack')
  String stack;

  @JsonKey(name: 'RemoteStatus')
  int remoteStatus;

  @JsonKey(name: 'RemoteError')
  RemoteError remoteError;

  factory SessionError.fromJson(Map<String, dynamic> json) => _$SessionErrorFromJson(json);
  Map<String, dynamic> toJson() => _$SessionErrorToJson(this);

  @override
  String toString() => [
        if (remoteStatus != null) "$remoteStatus ",
        "$errorType",
        if (info?.isNotEmpty ?? false) " ($info)",
        if (wrappedError?.isNotEmpty ?? false) ": $wrappedError",
        if (remoteError != null) "\n${jsonEncode(remoteError..stacktrace = null)}",
      ].join();
}

@JsonSerializable()
class RemoteError {
  RemoteError({this.status, this.errorName, this.description, this.message, this.stacktrace});

  @JsonKey(name: 'status')
  int status;

  @JsonKey(name: 'error')
  String errorName;

  @JsonKey(name: 'description')
  String description;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'stacktrace')
  String stacktrace;

  factory RemoteError.fromJson(Map<String, dynamic> json) => _$RemoteErrorFromJson(json);
  Map<String, dynamic> toJson() => _$RemoteErrorToJson(this);
}

@JsonSerializable()
class RequestorInfo {
  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'name')
  TranslatedValue name;

  @JsonKey(name: 'industry', nullable: true)
  TranslatedValue industry;

  @JsonKey(name: 'logo', nullable: true)
  String logo;

  @JsonKey(name: 'hostnames')
  List<String> hostnames;

  RequestorInfo({this.id, this.name, this.industry, this.logo, this.hostnames});
  factory RequestorInfo.fromJson(Map<String, dynamic> json) => _$RequestorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RequestorInfoToJson(this);
}
