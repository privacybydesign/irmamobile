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
import java.util.Arrays;

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
    private static final int ivLength = 12;

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

    private boolean keyExists() throws KeyStoreException {
        return keyStore.containsAlias(keyAlias);
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
            byte[] iv = cipher.getIV();
            if (iv.length != ivLength) {
                throw new RuntimeException("Unexpected IV length");
            }
            
            byte[] ciphertext = cipher.doFinal(plaintext);

            byte[] result = new byte[ivLength + ciphertext.length];
            System.arraycopy(iv, 0, result, 0, ivLength);
            System.arraycopy(ciphertext, 0, result, ivLength, ciphertext.length);

            return result;

        } catch (NoSuchAlgorithmException | UnrecoverableKeyException | KeyStoreException | InvalidKeyException | BadPaddingException | IllegalBlockSizeException e) {
            throw new RuntimeException(e);
        }
    }

    public byte[] decrypt(byte[] encrypted) {
        try {
            byte[] iv = Arrays.copyOfRange(encrypted, 0, ivLength);
            byte[] ciphertext = Arrays.copyOfRange(encrypted, ivLength, encrypted.length);
            Key secretKey = keyStore.getKey(keyAlias, null);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));

            return cipher.doFinal(ciphertext);

        } catch (NoSuchAlgorithmException | UnrecoverableKeyException | KeyStoreException | InvalidKeyException | BadPaddingException | IllegalBlockSizeException | InvalidAlgorithmParameterException e) {
            throw new RuntimeException(e);
        }
    }
}
