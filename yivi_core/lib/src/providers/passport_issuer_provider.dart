import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

final passportUrlProvider = StateProvider(
  (ref) => "https://passport-issuer.staging.yivi.app",
);

final passportIssuerProvider = Provider<PassportIssuer>(
  (ref) => DefaultPassportIssuer(hostName: ref.watch(passportUrlProvider)),
);
