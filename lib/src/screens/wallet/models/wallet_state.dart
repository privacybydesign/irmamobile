import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:meta/meta.dart';

@immutable
class WalletState with EquatableMixin {
  final List<Credential> credentials;

  WalletState({
    this.credentials,
  });

  WalletState copyWith({
    List<Credential> credentials,
  }) {
    return WalletState(
      credentials: credentials ?? this.credentials,
    );
  }

  @override
  List<Object> get props {
    return null;
  }
}
