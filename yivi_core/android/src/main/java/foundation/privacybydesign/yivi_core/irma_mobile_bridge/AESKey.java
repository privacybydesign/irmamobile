package foundation.privacybydesign.yivi_core.irma_mobile_bridge;

import android.content.Context;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;

public class AESKey {
    public static byte[] getKey(Context context) throws GeneralSecurityException, IOException {
        TEEEncryption tee = new TEEEncryption(context.getPackageManager());
        String path = context.getFilesDir() + "/storageKey";

        byte[] ciphertext = FileSystem.read(path);

        if (ciphertext == null) {
            byte[] key = generateKey();

            ciphertext = tee.encrypt(key);
            FileSystem.write(ciphertext, path);

            return key;
        }

        return tee.decrypt(ciphertext);
    }

    private static byte[] generateKey() {
        byte[] key = new byte[32];

        // The default SecureRandom is the platform CSPRNG. getInstanceStrong() gives the
        // same generator on Android, but may block on some devices.
        new SecureRandom().nextBytes(key);

        return key;
    }
}
