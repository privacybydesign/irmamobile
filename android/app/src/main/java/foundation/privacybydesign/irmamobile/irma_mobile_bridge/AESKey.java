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
            encrypted = generateKey();
        }

        return s.decrypt(encrypted);
    }

    // returns encrypted key
    private byte[] generateKey() {
        byte[] b = new byte[32];
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                SecureRandom.getInstanceStrong().nextBytes(b);
            } else {
                new SecureRandom().nextBytes(b);
            }
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }

        byte[] encrypted = s.encrypt(b);
        FileSystem.write(encrypted, path);

        return encrypted;
    }
}
