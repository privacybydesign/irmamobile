package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.Context;
import android.os.Build;

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

    private static byte[] generateKey() throws GeneralSecurityException {
        byte[] key = new byte[32];

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            SecureRandom.getInstanceStrong().nextBytes(key);
        } else {
            new SecureRandom().nextBytes(key);
        }

        return key;
    }
}
