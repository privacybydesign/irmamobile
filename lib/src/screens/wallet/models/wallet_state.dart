import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:meta/meta.dart';

@immutable
class WalletState with EquatableMixin {
  final Credentials credentials;
  final int newCardIndex;
  final bool showNewCardAnimation;

  WalletState({this.credentials, this.newCardIndex, this.showNewCardAnimation});

  WalletState copyWith({Credentials credentials, int newCardIndex, bool showNewCardAnimation}) {
    return WalletState(
      credentials: credentials ?? this.credentials,
      newCardIndex: newCardIndex ?? this.newCardIndex,
      showNewCardAnimation: showNewCardAnimation ?? this.showNewCardAnimation,
    );
  }

  @override
  List<Object> get props {
    return [
      credentials,
      showNewCardAnimation,
      newCardIndex,
    ];
  }
}
