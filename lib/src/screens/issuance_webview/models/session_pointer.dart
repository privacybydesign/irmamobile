import 'dart:convert';

class SessionPointer {
  String u;
  String irmaqr;

  SessionPointer({this.u, this.irmaqr});

  SessionPointer.fromJson(Map<String, dynamic> json) {
    u = json['u'];
    irmaqr = json['irmaqr'];
  }

  SessionPointer.fromURI(String uri) {
    var pointer;
    if (uri.indexOf("json/{") > -1) {
      var jsonString = uri.substring(uri.indexOf("json/{") + 5);
      pointer = SessionPointer.fromJson(
        jsonDecode(
          jsonString.substring(
            0,
            jsonString.indexOf("}") + 1,
          ),
        ),
      );
    }

    if (uri.indexOf("session#{") > -1) {
      var jsonString = uri.substring(uri.indexOf("session#{") + 8);
      pointer = SessionPointer.fromJson(
        jsonDecode(
          jsonString.substring(
            0,
            jsonString.indexOf("}") + 1,
          ),
        ),
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['u'] = this.u;
    data['irmaqr'] = this.irmaqr;
    return data;
  }
}

class MissingSessionPointer implements Exception {
  String errorMessage() {
    return 'URI does not contain a sessionpointer';
  }
}
