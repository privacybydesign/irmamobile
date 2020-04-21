import 'package:irmamobile/src/models/credentials.dart';

class WalletEvent {}

class CredentialUpdate extends WalletEvent {
  final Credentials credentials;
  final String newCardHash;
  final bool showNewCardAnimation;

  CredentialUpdate(this.credentials, this.newCardHash, {this.showNewCardAnimation});
}

class NewCardAnitmationShown extends WalletEvent {}
