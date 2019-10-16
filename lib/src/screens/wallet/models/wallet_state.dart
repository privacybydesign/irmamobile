import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:meta/meta.dart';

@immutable
class WalletState with EquatableMixin {
  final List<RichCredential> credentials;

  WalletState({
    this.credentials,
  });

  WalletState copyWith({
    List<RichCredential> credentials,
  }) {
    return new WalletState(
      credentials: credentials ?? this.credentials,
    );
  }

  @override
  List<Object> get props {
    return null;
  }
}
