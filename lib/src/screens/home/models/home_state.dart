import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:meta/meta.dart';

@immutable
class HomeState with EquatableMixin {
  final List<RichCredential> credentials;

  HomeState({
    this.credentials,
  });

  HomeState copyWith({
    List<RichCredential> credentials,
  }) {
    return new HomeState(
      credentials: credentials ?? this.credentials,
    );
  }

  @override
  List<Object> get props {
    return null;
  }
}
