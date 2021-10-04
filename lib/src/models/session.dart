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
  @JsonKey(name: 'wizard')
  final String? wizard;

  // Whether the session should be continued on the mobile device,
  // or on the device which has displayed a QR code
  @JsonKey(name: 'continueOnSecondDevice', defaultValue: false)
  bool continueOnSecondDevice;

  @Deprecated('This parameter is deprecated and will be removed at the end of 2020. Use clientReturnURL instead.')
  @JsonKey(name: 'returnURL')
  final String? returnURL;

  SessionPointer({
    this.wizard,
    this.continueOnSecondDevice = false,
    @Deprecated('This parameter is deprecated.') this.returnURL,
  });

  factory SessionPointer.fromJson(Map<String, dynamic> json) => _$SessionPointerFromJson(json);
  Map<String, dynamic> toJson() => _$SessionPointerToJson(this);

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
      String? jsonString;
      for (final regex in regexps) {
        final match = regex.stringMatch(content);
        if (match != null && match.isNotEmpty) {
          jsonString = Uri.decodeComponent(match);
          break;
        }
      }

      if (jsonString == null) {
        throw MissingSessionPointer();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final hasIrmaQR = json.containsKey('irmaqr');

      return hasIrmaQR ? IrmaQRSessionPointer.fromJson(json) : SessionPointer.fromJson(json);
    } catch (_) {
      throw MissingSessionPointer();
    }
  }

  @override
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  }) async {
    // Check whether returnURL is valid.
    if (returnURL != null) Uri.parse(returnURL!);

    if (wizard == null) return; // All checks below concern checks for the wizard.

    if (await irmaRepository.getIssueWizardActive().first) {
      throw UnsupportedError('cannot start wizard within a wizard');
    }

    final scheme = wizard!.contains('.') ? wizard!.split('.').first : null;

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

/// Representation of irmago's Qr struct. Validation is done by irmago.
@JsonSerializable(createFactory: false)
mixin IrmaQR {
  @JsonKey(name: 'u')
  late final String u;

  @JsonKey(name: 'irmaqr')
  late final String irmaqr;

  Map<String, dynamic> toJson() => _$IrmaQRToJson(this);
}

/// SessionPointer that contains an irmago Qr instance.
@JsonSerializable()
class IrmaQRSessionPointer extends SessionPointer with IrmaQR {
  IrmaQRSessionPointer({
    required String u,
    required String irmaqr,
    String? wizard,
    bool continueOnSecondDevice = false,
    @Deprecated('This parameter is deprecated.') String? returnURL,
  }) : super(wizard: wizard, continueOnSecondDevice: continueOnSecondDevice, returnURL: returnURL) {
    this.u = u;
    this.irmaqr = irmaqr;
  }

  factory IrmaQRSessionPointer.fromJson(Map<String, dynamic> json) => _$IrmaQRSessionPointerFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IrmaQRSessionPointerToJson(this);
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
