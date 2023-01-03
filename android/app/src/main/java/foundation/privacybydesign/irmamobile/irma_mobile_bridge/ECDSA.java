package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.app.KeyguardManager;
import android.content.pm.PackageManager;
import android.content.Context;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyInfo;
import android.security.keystore.KeyProperties;

import java.io.IOException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.SignatureException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.spec.ECGenParameterSpec;
import java.security.spec.InvalidKeySpecException;

public class ECDSA implements irmagobridge.Signer {
  private final KeyStore keyStore;
  private Context context;

  public ECDSA(Context context)
    throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException {
    this.context = context;
    keyStore = KeyStore.getInstance("AndroidKeyStore");
    keyStore.load(null);
  }

  public byte[] publicKey(String keyAlias)
    throws KeyStoreException,
    InvalidAlgorithmParameterException,
    NoSuchAlgorithmException,
    NoSuchProviderException {
    if (!keyExists(keyAlias)) {
      return generateKey(keyAlias);
    }

    return keyStore.getCertificate(keyAlias).getPublicKey().getEncoded();
  }

  public byte[] sign(String keyAlias, byte[] msg)
    throws NoSuchAlgorithmException,
    KeyStoreException,
    UnrecoverableKeyException,
    InvalidKeyException,
    SignatureException {
    Signature signature = Signature.getInstance("SHA256withECDSA");
    PrivateKey privateKey = (PrivateKey) keyStore.getKey(keyAlias, null);
    signature.initSign(privateKey);
    signature.update(msg);
    return signature.sign();
  }

  private boolean isDeviceLocked() {
    boolean isLocked = false;
    if (this.context != null) {
      KeyguardManager myKM = (KeyguardManager) this.context.getSystemService(Context.KEYGUARD_SERVICE);
      if (myKM != null && myKM.isKeyguardLocked()) {
        isLocked = true;
      }
    }
    return isLocked;
  }

  private byte[] generateKey(String keyAlias)
    throws NoSuchProviderException,
    NoSuchAlgorithmException,
    InvalidAlgorithmParameterException {

    if (isDeviceLocked()) {
      throw new InvalidAlgorithmParameterException("Key generation not allowed while device is locked");
    }

    KeyGenParameterSpec.Builder spec = new KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_SIGN)
      .setAlgorithmParameterSpec(new ECGenParameterSpec("secp256r1"))
      .setDigests(KeyProperties.DIGEST_SHA256);

    // setUnlockedDeviceRequired (when Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) which should work
    // throws exceptions on some devices, hence we use isDeviceLocked() for the time being
    // Issue tracker: https://issuetracker.google.com/u/1/issues/191391068
    // spec.setUnlockedDeviceRequired(true);

    if (this.context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)) {
      spec.setIsStrongBoxBacked(true);
    }

    KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore");
    keyPairGenerator.initialize(spec.build());
    KeyPair kp = keyPairGenerator.generateKeyPair();
    return kp.getPublic().getEncoded();
  }

  private boolean keyExists(String keyAlias) throws KeyStoreException {
    return keyStore.containsAlias(keyAlias);
  }
}
