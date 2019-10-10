package foundation.privacybydesign.irmamobile.plugins.irma_mobile_bridge;

import java.io.File;
import java.util.Arrays;
import android.text.TextUtils;

public class Path implements Comparable<Path> {
    private String path;

    public Path(String path) {
        this.path = path.replaceAll("/{2,}", "");
    }

    public Path resolve(Path other) {
        return this.resolve(other.toString());
    }

    public Path resolve(String other) {
        return new Path(this.path + "/" + other);
    }

    public boolean startsWith(Path other) {
        return this.startsWith(other.toString());
    }

    public boolean startsWith(String other) {
        return this.path.startsWith(other);
    }

    public Path subpath(int beginIndex, int endIndex) {
        String[] parts = this.path.split("/");

        if(endIndex < 0)
            endIndex = parts.length + 1 + endIndex;

        return new Path(TextUtils.join("/", Arrays.copyOfRange(parts, beginIndex, endIndex)));
    }

    public File toFile() {
        return new File(this.path);
    }

    public String toString() {
        return this.path;
    }

    @Override
    public int compareTo(Path other) {
        return this.path.compareTo(other.toString());
    }
}