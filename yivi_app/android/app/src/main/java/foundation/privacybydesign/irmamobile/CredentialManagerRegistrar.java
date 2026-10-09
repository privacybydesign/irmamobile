package foundation.privacybydesign.irmamobile;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import com.google.android.gms.identitycredentials.IdentityCredentialManager;
import com.google.android.gms.identitycredentials.RegistrationRequest;

import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Collections;

import foundation.privacybydesign.yivi_core.dcapi.DcApiRegistrar;

/**
 * Publishes the wallet to Android's Credential Manager so a browser calling {@code
 * navigator.credentials.get()} can reach it.
 *
 * <p>Two things go to the platform: the credential database built by irmago, and a matcher — a
 * WebAssembly program the platform runs, in its own process and with this app not running, to decide
 * whether the wallet holds anything that answers a request. Neither is a published format. The
 * matcher is the one from the Multipaz project (Apache-2.0), vendored as a prebuilt binary, and the
 * database's shape is whatever that binary parses.
 *
 * <p>Lives in the application rather than in {@code yivi_core} because both halves are things the
 * F-Droid build cannot have: Play Services, and a prebuilt binary.
 */
public class CredentialManagerRegistrar implements DcApiRegistrar {
  private static final String TAG = "CredentialManager";

  private static final String MATCHER_ASSET = "identitycredentialmatcher.wasm";

  /**
   * The credential type the current Credential Manager registers under, and the one older builds
   * do. Both are pushed: which of them the platform on this device reads is not something the app
   * can find out, and the cost of the extra call is one IPC on a path that already de-duplicates.
   */
  private static final String TYPE_DIGITAL_CREDENTIAL = "androidx.credentials.TYPE_DIGITAL_CREDENTIAL";

  private static final String TYPE_LEGACY = "com.credman.IdentityCredential";

  private static final String PREFS = "dcapi_registration";
  private static final String KEY_DATABASE_DIGEST = "database_sha256";
  private static final String KEY_MATCHER_DIGEST = "matcher_sha256";

  private final Context context;

  /** Cached across calls: the matcher is ~300 KB and never changes within a build. */
  private byte[] matcher;

  public CredentialManagerRegistrar(Context context) {
    this.context = context.getApplicationContext();
  }

  @Override
  public void register(byte[] database) {
    try {
      byte[] matcherBytes = loadMatcher();

      String databaseDigest = sha256(database);
      String matcherDigest = sha256(matcherBytes);

      // This runs after every finished session and every locale change, while the
      // wallet's contents usually did not move. Re-pushing an unchanged database
      // would hand the platform hundreds of kilobytes over IPC to tell it nothing.
      SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
      if (databaseDigest.equals(prefs.getString(KEY_DATABASE_DIGEST, null))
          && matcherDigest.equals(prefs.getString(KEY_MATCHER_DIGEST, null))) {
        return;
      }

      register(database, matcherBytes, TYPE_DIGITAL_CREDENTIAL);
      register(database, matcherBytes, TYPE_LEGACY);

      // Written before the calls are known to have succeeded would risk skipping
      // a retry of a failed registration, so it is written here -- but the calls
      // are asynchronous, so "here" is still before the outcome is known. The
      // failure mode that matters is the opposite one: a registration that
      // succeeded but was not recorded re-pushes the whole database on every
      // session forever. A registration that failed is retried the next time the
      // wallet's contents change, which is the same cadence as the event itself.
      prefs.edit()
          .putString(KEY_DATABASE_DIGEST, databaseDigest)
          .putString(KEY_MATCHER_DIGEST, matcherDigest)
          .apply();
    } catch (IOException | NoSuchAlgorithmException | RuntimeException e) {
      // Must not escape: this rides along with the credential refresh, and the
      // wallet's own UI must not go down because the platform would not take a
      // registration.
      Log.w(TAG, "could not register with Credential Manager", e);
    }
  }

  private void register(byte[] database, byte[] matcherBytes, String type) {
    IdentityCredentialManager.getClient(context)
        .registerCredentials(
            new RegistrationRequest(
                database,
                matcherBytes,
                type,
                /* requestType= */ "",
                /* protocolTypes= */ Collections.emptyList()))
        .addOnSuccessListener(result -> Log.i(TAG, "registered " + database.length + " bytes as " + type))
        .addOnFailureListener(e -> Log.w(TAG, "registration as " + type + " was refused", e));
  }

  private byte[] loadMatcher() throws IOException {
    if (matcher != null) {
      return matcher;
    }
    try (InputStream stream = context.getAssets().open(MATCHER_ASSET)) {
      matcher = readAll(stream);
    }
    return matcher;
  }

  private static byte[] readAll(InputStream stream) throws IOException {
    java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
    byte[] buffer = new byte[8192];
    int read;
    while ((read = stream.read(buffer)) != -1) {
      out.write(buffer, 0, read);
    }
    return out.toByteArray();
  }

  private static String sha256(byte[] value) throws NoSuchAlgorithmException {
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(value);
    StringBuilder hex = new StringBuilder(digest.length * 2);
    for (byte b : digest) {
      hex.append(Character.forDigit((b >> 4) & 0xf, 16));
      hex.append(Character.forDigit(b & 0xf, 16));
    }
    return hex.toString();
  }
}
