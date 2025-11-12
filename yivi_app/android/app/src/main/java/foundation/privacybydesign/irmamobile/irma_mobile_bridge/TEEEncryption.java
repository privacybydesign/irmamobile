package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.pm.PackageManager;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.InvalidAlgorithmParameterException;
import java.security.Key;
import java.security.KeyStore;
import java.util.Arrays;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.spec.GCMParameterSpec;

// Encryption and decryption via the Trusted Execution Environment (TEE)
public class TEEEncryption {
    private final PackageManager packageManager;
    private final KeyStore keyStore;
    private final String keyAlias = "storageKey";
    private final Cipher cipher;
    private static final int ivLength = 12;

    public TEEEncryption(PackageManager pm) throws GeneralSecurityException, IOException {
        packageManager = pm;
        keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);
        cipher = Cipher.getInstance("AES/GCM/NoPadding");

        if (!keyExists())
            generateKey();
    }

    private boolean keyExists() throws GeneralSecurityException {
        return keyStore.containsAlias(keyAlias);
    }

    protected void generateKey() throws GeneralSecurityException {
        KeyGenParameterSpec.Builder spec = new KeyGenParameterSpec.Builder(keyAlias,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setKeySize(256);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && 
        packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)) {
                spec.setIsStrongBoxBacked(true);
        }

        KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
        keyGenerator.init(spec.build());
        keyGenerator.generateKey();
    }

    public byte[] encrypt(byte[] plaintext) throws GeneralSecurityException {
        Key secretKey = keyStore.getKey(keyAlias, null);
        cipher.init(Cipher.ENCRYPT_MODE, secretKey);

        // The cipher will create an IV during initiation. No custom IV can be specified
        // when using the algorithm AES/GCM/NoPadding.
        byte[] iv = cipher.getIV();
        if (iv.length != ivLength) {
            throw new InvalidAlgorithmParameterException("Unexpected IV length");
        }

        byte[] ciphertext = cipher.doFinal(plaintext);

        byte[] result = new byte[ivLength + ciphertext.length];
        System.arraycopy(iv, 0, result, 0, ivLength);
        System.arraycopy(ciphertext, 0, result, ivLength, ciphertext.length);

        return result;
    }

    public byte[] decrypt(byte[] ciphertext) throws GeneralSecurityException {
        byte[] iv = Arrays.copyOfRange(ciphertext, 0, ivLength);
        byte[] encryptedMessage = Arrays.copyOfRange(ciphertext, ivLength, ciphertext.length);
        Key secretKey = keyStore.getKey(keyAlias, null);
        cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));

        return cipher.doFinal(encryptedMessage);
    }
}
