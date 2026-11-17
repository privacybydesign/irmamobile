import "package:material_ui/material_ui.dart";

import "../../../models/session.dart";
import "../../../providers/contact_issuance_provider.dart";

/// What a page of adding an e-mail address or phone number keeps besides
/// the flow's state: the code boxes and their focus, whether a code is
/// being checked, and whether a new code was just sent. Shared by the
/// sheet's step and the enrollment step; owned by the page (it holds a
/// text controller and a focus node).
class ContactStepController extends ChangeNotifier {
  ContactStepController(this._flowOf);

  /// The flow's notifier, read when needed.
  final ContactIssuance Function() _flowOf;

  final code = TextEditingController();
  final codeFocus = FocusNode();

  /// A code is being checked: a second one is ignored.
  bool get verifying => _verifying;
  var _verifying = false;

  /// A new code was sent from the code page: "We sent a new code."
  bool get sentAgain => _sentAgain;
  var _sentAgain = false;

  var _disposed = false;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// The first code to [target].
  Future<void> send(String target, String language) {
    _sentAgain = false;
    _changed();
    return _flowOf().send(target, language: language);
  }

  /// A new code to [target], from the code page: the boxes cleared.
  void sendAgain(String target, String language) {
    code.clear();
    _sentAgain = true;
    _changed();
    _flowOf().send(target, language: language);
  }

  /// Checks [value] (upper-cased), once at a time. Not right: the boxes
  /// cleared and focused for another try, and null; the error stays until
  /// the next character.
  Future<SessionPointer?> verify(String value) async {
    if (_verifying) return null;
    _verifying = true;
    _changed();
    final session = await _flowOf().verify(value.toUpperCase());
    if (_disposed) return session;
    _verifying = false;
    if (session == null) {
      code.clear();
      codeFocus.requestFocus();
    }
    _changed();
    return session;
  }

  /// Back to the address, filled in, to change it.
  void change() {
    code.clear();
    _sentAgain = false;
    _changed();
    _flowOf().backToAddress();
  }

  /// A character typed after an error clears it.
  void codeTyped(String text, {required bool hasError}) {
    if (text.isNotEmpty && hasError) _flowOf().clearError();
  }

  @override
  void dispose() {
    _disposed = true;
    code.dispose();
    codeFocus.dispose();
    super.dispose();
  }
}
