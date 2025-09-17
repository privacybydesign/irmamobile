import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'passport_data_result.g.dart';

@JsonSerializable()
class PassportDataResult {
  @JsonKey(name: 'data_groups')
  final Map<String, String> dataGroups;

  @JsonKey(name: 'ef_sod')
  final String efSod;

  @JsonKey(name: 'session_id')
  final String? sessionId;

  @JsonKey(name: 'nonce')
  @Uint8ListConverter()
  final Uint8List? nonce;

  @JsonKey(name: 'aa_signature')
  @Uint8ListConverter()
  final Uint8List? aaSignature;

  PassportDataResult({
    required this.dataGroups,
    required this.efSod,
    this.sessionId,
    this.nonce,
    this.aaSignature,
  });

  factory PassportDataResult.fromJson(Map<String, dynamic> json) => _$PassportDataResultFromJson(json);

  Map<String, dynamic> toJson() => _$PassportDataResultToJson(this);
}

/// Converter to encode/decode Uint8List <-> hex string
class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    final buffer = Uint8List(json.length ~/ 2);
    for (var i = 0; i < json.length; i += 2) {
      buffer[i ~/ 2] = int.parse(json.substring(i, i + 2), radix: 16);
    }
    return buffer;
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    final StringBuffer buffer = StringBuffer();
    for (final b in object) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
