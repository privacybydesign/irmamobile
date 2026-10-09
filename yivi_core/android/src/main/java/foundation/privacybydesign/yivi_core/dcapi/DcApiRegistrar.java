package foundation.privacybydesign.yivi_core.dcapi;

/**
 * Publishes the wallet's contents to the platform's Digital Credentials API provider registry.
 *
 * <p>This interface is the whole of Credential Manager inside {@code yivi_core}, and that is
 * deliberate. Registering requires two things this module must not contain: a dependency on Google
 * Play Services, and a prebuilt WebAssembly matcher binary. {@code yivi_core} is shared with the
 * F-Droid application, which is built by a server that permits neither — it cross-compiles
 * SQLCipher from source for exactly that reason (see {@code yivi_fdroid/fdroid_build.sh}). So the
 * implementation lives in the Play application and is installed here at startup; the F-Droid build
 * installs nothing and the wallet simply never appears in a credential picker, which is the
 * situation it is in today anyway.
 *
 * <p>Registration is a push. The platform keeps whatever snapshot it was last given and consults it
 * with the wallet not running, so a fresh database is handed over whenever the wallet's credentials
 * or locale change.
 */
public interface DcApiRegistrar {
  /**
   * Registers the given credential database with the platform.
   *
   * <p>Called on whichever thread the Go bridge dispatched from, not the UI thread, and called
   * often — every finished session produces one. Implementations are expected to do their own
   * de-duplication rather than re-registering an unchanged database.
   *
   * <p>Must not throw. A registration that fails leaves the platform holding the previous snapshot,
   * which is a worse wallet but a working one; letting the failure escape would take down the
   * credential refresh this rides along with.
   *
   * @param database CBOR, in the private format the matcher shipped alongside it parses.
   */
  void register(byte[] database);
}
