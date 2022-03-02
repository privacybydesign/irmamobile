package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.pm.PackageManager;
import android.os.Build;

import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;

import java.io.IOException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.GCMParameterSpec;

public class Storage {
    private final PackageManager packageManager;
    private final KeyStore keyStore;
    private final String keyAlias = "storageKey";
    private final Cipher cipher;

    public Storage(PackageManager pm) {
        packageManager = pm;

        try {
            keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);
            cipher = Cipher.getInstance("AES/GCM/NoPadding");

            if (!keyExists())
                generateKey();
        } catch (KeyStoreException | CertificateException | IOException | NoSuchAlgorithmException | NoSuchPaddingException e) {
            throw new RuntimeException(e);
        }
    }

    private boolean keyExists() {
        try {
            return keyStore.containsAlias(keyAlias);
        } catch (KeyStoreException e) {
            return false;
        }
    }

    protected void generateKey() {
        KeyGenParameterSpec.Builder spec = new KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setKeySize(256);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            spec.setUnlockedDeviceRequired(true);
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE))
                spec.setIsStrongBoxBacked(true);
        }

        try {
            KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            keyGenerator.init(spec.build());
            keyGenerator.generateKey();
        } catch (NoSuchAlgorithmException | NoSuchProviderException | InvalidAlgorithmParameterException e) {
            throw new RuntimeException(e);
        }
    }

    public byte[] encrypt(byte[] plaintext) {
        try {
            Key secretKey = keyStore.getKey(keyAlias, null);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);

            return cipher.doFinal(plaintext);

        } catch (NoSuchAlgorithmException | UnrecoverableKeyException | KeyStoreException | InvalidKeyException | BadPaddingException | IllegalBlockSizeException e) {
            throw new RuntimeException(e);
        }
    }

    public byte[] decrypt(byte[] encrypted) {
        try {
            Key secretKey = keyStore.getKey(keyAlias, null);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, cipher.getIV()));

            return cipher.doFinal(encrypted);

        } catch (NoSuchAlgorithmException | UnrecoverableKeyException | KeyStoreException | InvalidKeyException | BadPaddingException | IllegalBlockSizeException | InvalidAlgorithmParameterException e) {
            throw new RuntimeException(e);
        }
    }
}
