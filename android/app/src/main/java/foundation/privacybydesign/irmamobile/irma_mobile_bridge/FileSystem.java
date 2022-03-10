package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.os.Build;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Paths;

public class FileSystem {
    public static byte[] read(String path) throws IOException {
        byte[] bytes;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                bytes = Files.readAllBytes(Paths.get(path));
            } catch (NoSuchFileException e) {
                return null;
            }
        } else {
            File file = new File(path);
            bytes = new byte[(int) file.length()];

            FileInputStream fis = null;
            try {
                fis = new FileInputStream(file);
                fis.read(bytes);
            }  catch (FileNotFoundException e) {
                return null;
            } finally {
                if (fis != null) {
                    fis.close();
                }
            }
        }

        return bytes;
    }

    public static void write(byte[] data, String path) throws IOException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Files.createFile(Paths.get(path));
            Files.write(Paths.get(path), data);
        } else {
            FileOutputStream fos = null;
            try {
                fos = new FileOutputStream(path);
                fos.write(data);
            } finally {
                if (fos != null) {
                    fos.close();
                }
            }
        }
    }
}
