// This file is not null safe yet.
// @dart=2.11

import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:meta/meta.dart';

@immutable
class WalletState with EquatableMixin {
  final Credentials credentials;
  final String newCardHash;
  final bool showNewCardAnimation;

  WalletState({this.credentials, this.newCardHash, this.showNewCardAnimation});

  WalletState copyWith({Credentials credentials, String newCardHash, bool showNewCardAnimation}) {
    return WalletState(
      credentials: credentials ?? this.credentials,
      newCardHash: newCardHash ?? this.newCardHash,
      showNewCardAnimation: showNewCardAnimation ?? this.showNewCardAnimation,
    );
  }

  @override
  List<Object> get props {
    return [
      credentials,
      showNewCardAnimation,
      newCardHash,
    ];
  }
}
