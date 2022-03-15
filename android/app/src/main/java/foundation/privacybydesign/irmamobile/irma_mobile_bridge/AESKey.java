package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.Context;
import android.os.Build;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;

public class AESKey {
    public static byte[] getKey(Context context) {
        AES aes = new AES(context.getPackageManager());
        String path = context.getFilesDir() + "/storageKey";

        try {
            byte[] encrypted = FileSystem.read(path);

            if (encrypted == null) {
                byte[] key = generateKey();

                encrypted = aes.encrypt(key);
                FileSystem.write(encrypted, path);

                return key;
            }

            return aes.decrypt(encrypted);

        } catch (GeneralSecurityException | IOException e) {
            throw new RuntimeException(e);
        }
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
