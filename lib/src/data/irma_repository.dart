import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/issuer.dart';

abstract class IrmaRepository {
  IrmaRepository();

  // TODO: Change abstract outline to match realistic irmago scenario's.
  Credential getCredential();

  // TODO: Change abstract outline to match realistic irmago scenario's.
  List<Issuer> getIssuers();
}
