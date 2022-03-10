package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.Context;
import android.os.Build;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;

public class AESKey {
    private Storage s;
    private String path;

    public AESKey(Context context) {
        s = new Storage(context.getPackageManager());
        path = context.getFilesDir() + "/storageKey";
    }

    public byte[] getKey() {
        try {
            byte[] encrypted = FileSystem.read(path);

            if (encrypted == null) {
                byte[] key = generateKey();

                encrypted = s.encrypt(key);
                FileSystem.write(encrypted, path);

                return key;
            }

            return s.decrypt(encrypted);

        } catch (GeneralSecurityException | IOException e) {
            throw new RuntimeException(e);
        }
    }

    private byte[] generateKey() throws GeneralSecurityException {
        byte[] key = new byte[32];
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            SecureRandom.getInstanceStrong().nextBytes(key);
        } else {
            new SecureRandom().nextBytes(key);
        }

        return key;
    }
}
