package foundation.privacybydesign.yivi_core.dcapi;

import androidx.annotation.Nullable;

/**
 * Holds the {@link DcApiRegistrar} the application installed, if any.
 *
 * <p>Static because of who the two parties are and when they exist. The producer is the Go bridge,
 * which is created by the Flutter plugin deep inside the engine's lifecycle and takes no
 * application-supplied collaborators; the consumer is the application, which knows at build time
 * whether it can register at all. Threading a nullable registrar down through the plugin binding
 * would touch four classes to deliver one optional reference.
 *
 * <p>An absent registrar is the ordinary state, not an error: it is what the F-Droid build looks
 * like, and what any build looks like before the application has started.
 */
public final class DcApiRegistration {
  @Nullable private static volatile DcApiRegistrar registrar;

  private DcApiRegistration() {}

  /**
   * Installs the registrar to publish credential databases through. Call before the wallet starts —
   * {@code MainActivity.configureFlutterEngine} is early enough — or the first database, the one
   * built when the app reports itself ready, is dropped.
   */
  public static void install(@Nullable DcApiRegistrar value) {
    registrar = value;
  }

  /** Returns the installed registrar, or null when this build cannot register. */
  @Nullable
  public static DcApiRegistrar get() {
    return registrar;
  }
}
