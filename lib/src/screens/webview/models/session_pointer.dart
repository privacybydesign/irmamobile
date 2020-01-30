import 'dart:convert';

@Deprecated("Use SessionPointer and integrate parsing logic there")
class DeprecateMeSessionPointer {
  String u;
  String irmaqr;

  DeprecateMeSessionPointer({this.u, this.irmaqr});

  DeprecateMeSessionPointer.fromJson(Map<String, dynamic> json) {
    u = json['u'] as String;
    irmaqr = json['irmaqr'] as String;
  }

  DeprecateMeSessionPointer.fromURI(String uri) {
    DeprecateMeSessionPointer pointer;
    if (uri.contains("json/{")) {
      final jsonString = uri.substring(uri.indexOf("json/{") + 5);
      pointer = DeprecateMeSessionPointer.fromJson(
        jsonDecode(
          jsonString.substring(
            0,
            jsonString.indexOf("}") + 1,
          ),
        ) as Map<String, dynamic>,
      );
    }

    if (uri.contains("session#{")) {
      final jsonString = uri.substring(uri.indexOf("session#{") + 8);
      pointer = DeprecateMeSessionPointer.fromJson(
        jsonDecode(
          jsonString.substring(
            0,
            jsonString.indexOf("}") + 1,
          ),
        ) as Map<String, dynamic>,
      );
      u = pointer.u;
      irmaqr = pointer.irmaqr;
    }

    if (pointer == null) {
      throw MissingSessionPointer;
    }

    u = pointer.u;
    irmaqr = pointer.irmaqr;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['u'] = u;
    data['irmaqr'] = irmaqr;
    return data;
  }
}

class MissingSessionPointer implements Exception {
  String errorMessage() {
    return 'URI does not contain a sessionpointer';
  }
}
