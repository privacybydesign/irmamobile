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
    public static byte[] read(String path) {
        byte[] bytes;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                bytes = Files.readAllBytes(Paths.get(path));
            } catch (NoSuchFileException e) {
                return null;
            } catch (IOException e) {
                throw new RuntimeException(e);
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
            } catch (IOException e) {
                throw new RuntimeException(e);
            } finally {
                if (fis != null) {
                    try {
                        fis.close();
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                }
            }
        }

        return bytes;
    }

    public static void write(byte[] data, String path) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                Files.createFile(Paths.get(path));
                Files.write(Paths.get(path), data);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        } else {
            try {
                FileOutputStream fos = new FileOutputStream(path);
                fos.write(data);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
