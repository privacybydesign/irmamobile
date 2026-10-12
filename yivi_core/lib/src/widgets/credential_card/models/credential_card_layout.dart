/// How a credential card is laid out.
enum CredentialCardLayout {
  standard,

  /// The card on the permission screen of a document: a tighter header, more
  /// air between the rows and the validity in two cells.
  document;

  /// Line heights of the document layout: 14 pt text on 20, 16 pt text on 22.
  static const smallLineHeight = 20 / 14;
  static const bodyLineHeight = 22 / 16;
}
