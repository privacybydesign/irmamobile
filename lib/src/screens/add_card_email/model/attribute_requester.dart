import 'package:http/http.dart' as http;

abstract class EmailAttributeRequester {
  Future<bool> requestAttribute(String email, String language);
}

class EmailAttributeRequesterHttpBackend implements EmailAttributeRequester {
  final String url;
  EmailAttributeRequesterHttpBackend(this.url);

  @override
  Future<bool> requestAttribute(String email, String language) async {
    var response = await http.post(url, body: {
      "email": email,
      "language": language,
    });
    return (response.statusCode >= 200 && response.statusCode < 300);
  }
}

class EmailAttributeRequesterMock implements EmailAttributeRequester {
  final bool result;
  EmailAttributeRequesterMock(this.result);

  @override
  Future<bool> requestAttribute(String email, String language) async {
    await Future.delayed(Duration(seconds: 2));
    return result;
  }
}
