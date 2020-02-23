import 'package:irmamobile/src/models/credentials.dart';

class WalletEvent {}

class CredentialUpdate extends WalletEvent {
  final Credentials credentials;
  final int newCardIndex;
  final bool showNewCardAnimation;

  CredentialUpdate(this.credentials, this.newCardIndex, {this.showNewCardAnimation});
}

class NewCardAnitmationShown extends WalletEvent {}
