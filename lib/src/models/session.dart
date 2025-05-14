import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../data/irma_repository.dart';
import 'translated_value.dart';

part 'session.g.dart';

class MissingPointer implements Exception {
  final String details;

  MissingPointer({required this.details});

  String errorMessage() {
    return 'URI does not contain a session or wizard pointer: $details';
  }
}

/// Interface for all pointers referring to new sessions and issue wizards.
abstract class Pointer {
  Future<void> validate({required IrmaRepository irmaRepository, RequestorInfo? requestor});

  factory Pointer.fromString(String content) {
    if (content.startsWith('eudi-openid4vp://')) {
      final uri = Uri.parse(content);
      final requestUri = uri.queryParameters['request_uri'];
      final clientId = uri.queryParameters['client_id'];
      if (clientId == null) {
        throw MissingPointer(details: 'expected "client_id" to be present in query parameters, but it wasn\'t');
      }
      if (requestUri == null) {
        throw MissingPointer(details: 'expected "request_uri" to be present in query parameters, but it wasn\'t');
      }
      return SessionPointer(
        u: content,
        irmaqr: 'disclosing',
      );
    }

    // Use lookahead and lookbehinds to block out the non-JSON part of the string
    final regexps = [
      RegExp('(?<=^irma://qr/json/).*'),
      RegExp('(?<=^cardemu://qr/json/).*'),
      RegExp('(?<=^intent://qr/json/).*(?=#)'),
      RegExp('(?<=^https://irma.app/-/session#).*'),
      RegExp('(?<=^https://irma.app/-pilot/session#).*'),
      RegExp('(?<=^https://open.yivi.app/-/session#).*'),
      RegExp('(?<=^https://open.yivi.app/-pilot/session#).*'),
      RegExp('.*', multiLine: true, dotAll: true),
    ];

    final Map<String, dynamic> json;
    try {
      String? jsonString;
      for (final regex in regexps) {
        final match = regex.stringMatch(content);
        if (match != null && match.isNotEmpty) {
          jsonString = Uri.decodeComponent(match);
          break;
        }
      }

      if (jsonString == null) {
        throw MissingPointer(details: 'unsupported uri scheme');
      }

      json = jsonDecode(jsonString) as Map<String, dynamic>;

      final hasWizard = json.containsKey('wizard');
      final hasURL = json.containsKey('u');
      if (hasWizard && hasURL) {
        return IssueWizardSessionPointer.fromJson(json);
      } else if (hasWizard) {
        return IssueWizardPointer.fromJson(json);
      } else {
        return SessionPointer.fromJson(json);
      }
    } catch (e) {
      throw MissingPointer(details: e.toString());
    }
  }
}

/// A pointer that refers to an issue wizard only.
@JsonSerializable()
class IssueWizardPointer implements Pointer {
  @JsonKey(name: 'wizard', required: true)
  final String wizard;

  IssueWizardPointer(this.wizard);

  factory IssueWizardPointer.fromJson(Map<String, dynamic> json) => _$IssueWizardPointerFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardPointerToJson(this);

  @override
  Future<void> validate({required IrmaRepository irmaRepository, RequestorInfo? requestor}) async {
    if (await irmaRepository.getIssueWizardActive().first) {
      throw UnsupportedError('cannot start wizard within a wizard');
    }

    final scheme = wizard.contains('.') ? wizard.split('.').first : null;

    final irmaConfiguration = await irmaRepository.getIrmaConfiguration().first;
    if (!irmaConfiguration.issueWizards.containsKey(wizard) ||
        !irmaConfiguration.requestorSchemes.containsKey(scheme)) {
      throw ArgumentError.value(wizard, 'wizard');
    }

    final demoScheme = irmaConfiguration.requestorSchemes[scheme]!.demo;
    final developerMode = await irmaRepository.getDeveloperMode().first;
    if (!developerMode && demoScheme) {
      throw UnsupportedError('cannot start wizard from demo scheme: developer mode not enabled');
    }

    final wizardData = irmaConfiguration.issueWizards[wizard]!;
    if (demoScheme || wizardData.allowOtherRequestors) {
      return;
    }

    if (requestor == null) {
      throw UnsupportedError('cannot start wizard: unknown requestor');
    }
    if (wizardData.id.split('.').getRange(0, 2).join('.') != requestor.id) {
      throw UnsupportedError('cannot start wizard not belonging to session requestor');
    }
  }
}

/// A pointer that refers to a new IRMA session.
@JsonSerializable()
class SessionPointer implements Pointer {
  @JsonKey(name: 'u', required: true)
  final String u;

  @JsonKey(name: 'irmaqr', required: true)
  final String irmaqr;

  /// Whether the session should be continued on the mobile device,
  /// or on the device which has displayed a QR code.
  /// Field is not always specified in QRs now.
  /// To make sure we can override its value if necessary, the field is not final fow now.
  @JsonKey(name: 'continueOnSecondDevice')
  bool continueOnSecondDevice;

  SessionPointer({
    required this.u,
    required this.irmaqr,
    this.continueOnSecondDevice = false,
  });

  factory SessionPointer.fromJson(Map<String, dynamic> json) => _$SessionPointerFromJson(json);
  Map<String, dynamic> toJson() => _$SessionPointerToJson(this);

  @override
  Future<void> validate({required IrmaRepository irmaRepository, RequestorInfo? requestor}) async {}
}

/// A pointer that refers to an issue wizard being followed by an IRMA session.
class IssueWizardSessionPointer implements IssueWizardPointer, SessionPointer {
  final IssueWizardPointer _wizardPointer;
  final SessionPointer _sessionPointer;

  IssueWizardSessionPointer(this._wizardPointer, this._sessionPointer);

  factory IssueWizardSessionPointer.fromJson(Map<String, dynamic> json) => IssueWizardSessionPointer(
        IssueWizardPointer.fromJson(json),
        SessionPointer.fromJson(json),
      );

  @override
  bool get continueOnSecondDevice => _sessionPointer.continueOnSecondDevice;

  @override
  set continueOnSecondDevice(bool value) => _sessionPointer.continueOnSecondDevice = value;

  @override
  String get irmaqr => _sessionPointer.irmaqr;

  @override
  String get wizard => _wizardPointer.wizard;

  @override
  String get u => _sessionPointer.u;

  @override
  Map<String, dynamic> toJson() => {
        ..._wizardPointer.toJson(),
        ..._sessionPointer.toJson(),
      };

  @override
  Future<void> validate({required IrmaRepository irmaRepository, RequestorInfo? requestor}) async {
    await _wizardPointer.validate(irmaRepository: irmaRepository, requestor: requestor);
    await _sessionPointer.validate(irmaRepository: irmaRepository, requestor: requestor);
  }
}

@JsonSerializable()
class SessionError {
  SessionError({
    required this.errorType,
    required this.info,
    this.wrappedError = '',
    this.stack = '',
    this.remoteStatus,
    this.remoteError,
  });

  @JsonKey(name: 'ErrorType')
  final String errorType;

  @JsonKey(name: 'WrappedError')
  final String wrappedError;

  @JsonKey(name: 'Info')
  final String info;

  @JsonKey(name: 'Stack')
  final String stack;

  @JsonKey(name: 'RemoteStatus')
  final int? remoteStatus;

  @JsonKey(name: 'RemoteError')
  final RemoteError? remoteError;

  bool get reportable => !['https', 'notSupported'].contains(errorType);

  factory SessionError.fromJson(Map<String, dynamic> json) => _$SessionErrorFromJson(json);
  Map<String, dynamic> toJson() => _$SessionErrorToJson(this);

  @override
  String toString() => [
        if (remoteStatus != null && remoteStatus! > 0) '$remoteStatus ',
        errorType,
        if (info.isNotEmpty) ' ($info)',
        if (wrappedError.isNotEmpty) ': $wrappedError',
        if (remoteError != null) '\n$remoteError',
      ].join();
}

@JsonSerializable()
class RemoteError {
  RemoteError({this.status, this.errorName, this.description, this.message, this.stacktrace});

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'error')
  final String? errorName;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'stacktrace')
  final String? stacktrace;

  RemoteError copyWithoutStacktrace() => RemoteError(
        status: status,
        errorName: errorName,
        description: description,
        message: message,
      );

  factory RemoteError.fromJson(Map<String, dynamic> json) => _$RemoteErrorFromJson(json);
  Map<String, dynamic> toJson() => _$RemoteErrorToJson(this);

  @override
  String toString() => jsonEncode(copyWithoutStacktrace());
}

@JsonSerializable()
class RequestorInfo {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'name')
  final TranslatedValue name;

  @JsonKey(name: 'industry') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue industry;

  @JsonKey(name: 'logo')
  final String? logo;

  @JsonKey(name: 'logoPath')
  final String? logoPath;

  @JsonKey(name: 'unverified')
  final bool unverified;

  @JsonKey(name: 'hostnames')
  final List<String> hostnames;

  RequestorInfo({
    required this.name,
    this.unverified = true,
    this.hostnames = const [],
    this.industry = const TranslatedValue.empty(),
    this.id,
    this.logo,
    this.logoPath,
  });
  factory RequestorInfo.fromJson(Map<String, dynamic> json) => _$RequestorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RequestorInfoToJson(this);
}
