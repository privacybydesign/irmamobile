package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.Context;
import android.os.Build;

import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

public class AESKey {
    private Storage s;
    private String path;

    public AESKey(Context context) {
        s = new Storage(context.getPackageManager());
        path = context.getFilesDir() + "/storageKey";
    }

    public byte[] getKey() {
        byte[] encrypted = FileSystem.read(path);

        if (encrypted == null) {
            return generateKey();
        }

        return s.decrypt(encrypted);
    }

    private byte[] generateKey() {
        byte[] key = new byte[32];
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                SecureRandom.getInstanceStrong().nextBytes(key);
            } else {
                new SecureRandom().nextBytes(key);
            }
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }

        byte[] encrypted = s.encrypt(key);
        FileSystem.write(encrypted, path);

        return key;
    }
}
