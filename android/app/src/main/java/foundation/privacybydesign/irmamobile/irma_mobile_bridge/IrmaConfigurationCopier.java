package foundation.privacybydesign.irmamobile.irma_mobile_bridge;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Build;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Objects;

// TODO: Use a more reasonable approach to path handling, rather than reinventing a couple
// of classes due to the complete implementation missing from some Android versions

public class IrmaConfigurationCopier {
  private final AssetManager assetManager;

  private final Path sourceConfigurationPath;
  public Path destAssetsPath;

  private ArrayList<Path> configurationFilePaths;

  public IrmaConfigurationCopier(Context context) throws IOException {
    this.assetManager = context.getAssets();

    this.sourceConfigurationPath = Paths.get("irma_configuration");
    this.destAssetsPath = Paths.get(context.getFilesDir().getPath()).resolve("assets");

    this.ensureDirExists(Paths.get(context.getFilesDir().getPath()).resolve("tmp"));
    this.ensureConfigurationAssets();
  }

  private void ensureConfigurationAssets() throws IOException {
    this.ensureDirExists(this.destAssetsPath);
    this.ensureDirExists(this.destAssetsPath.resolve("irma_configuration"));

    String[] schemes = this.assetManager.list(this.sourceConfigurationPath.toString());
    assert schemes != null;
    for (String scheme : schemes) {
      // Skip files (eg. READMEs) to get scheme folders
      Path sourceSchemePath = sourceConfigurationPath.resolve(scheme);
      if (Objects.requireNonNull(this.assetManager.list(sourceSchemePath.toString())).length == 0)
        continue;

      Path destSchemePath = this.destAssetsPath.resolve(sourceSchemePath);
      this.ensureDirExists(destSchemePath);

      // Decide if we should copy the scheme, by comparing the timestamp in the bundle assets
      // and the one in our assets folder. If the latter does not exist or its value is smaller
      // than the one from the bundle assets, copy the scheme out of the bundle to the assets dir
      Path destTimestampPath = destSchemePath.resolve("timestamp");

      if (destTimestampPath.toFile().exists()) {
        try {
          Path sourceTimestampPath = sourceSchemePath.resolve("timestamp");
          long sourceTimestamp = this.readTimestamp(this.assetManager.open(sourceTimestampPath.toString()));
          long destTimestamp = 0;
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            destTimestamp = this.readTimestamp(Files.newInputStream(destTimestampPath.toFile().toPath()));
          }

          if (sourceTimestamp <= destTimestamp)
            continue;

          // If there's an error while checking timestamps, always copy
        } catch (NumberFormatException e) {
          Log.e("AssetsCopier", "Failed to parse timestamps for scheme " + scheme, e);
        }
      }

      System.out.printf("Copying %s from assets\n", sourceSchemePath);
      this.copyScheme(sourceSchemePath);
      System.out.printf("Done copying %s from assets\n", sourceSchemePath);
    }
  }

  private void ensureDirExists(Path path) throws IOException {
    File dir = path.toFile();
    if (!dir.exists() && !dir.mkdir())
      throw new IOException("Could not create dir " + path);
  }

  private long readTimestamp(InputStream stream) throws IOException {
    return Long.parseLong(new BufferedReader(new InputStreamReader(stream)).readLine());
  }

  private ArrayList<Path> listAssetFilesRecursively(AssetManager assetManager, Path basePath) throws IOException {
    ArrayList<Path> results = new ArrayList<>();
    recurseAssets(assetManager, basePath, results);
    return results;
  }

  private void recurseAssets(AssetManager assetManager, Path path, ArrayList<Path> results) throws IOException {
    String[] children = assetManager.list(path.toString());
    if (children == null || children.length == 0) {
      // Leaf file
      results.add(path);
    } else {
      for (String child : children) {
        Path childPath = path.resolve(child);
        recurseAssets(assetManager, childPath, results);
      }
    }
  }

  private void collectConfigurationFilePaths() throws IOException {
    if (this.configurationFilePaths != null)
      return;

    this.configurationFilePaths = listAssetFilesRecursively(this.assetManager, new Path("irma_configuration"));
    Collections.sort(this.configurationFilePaths);
  }

  private void copyScheme(Path sourceSchemePath) throws IOException {
    this.collectConfigurationFilePaths();

    // Select all the files in the manifest for this scheme
    for (Path configurationFilePath : this.configurationFilePaths) {
      if (configurationFilePath.startsWith(sourceSchemePath)) {
        // Create a folder structure for this file, then copy over
        this.destAssetsPath.resolve(configurationFilePath.subpath(0, -2)).toFile().mkdirs();
        this.copyFile(configurationFilePath);
      }
    }
  }

  private void copyFile(Path path) throws IOException {
    InputStream sourceStream = this.assetManager.open(path.toString());

    Path destPath = this.destAssetsPath.resolve(path);
    OutputStream destStream = null;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      destStream = Files.newOutputStream(destPath.toFile().toPath());
    }

    assert destStream != null;
    byte[] buffer = new byte[1024];
    int read;
    while ((read = sourceStream.read(buffer)) != -1) {
      destStream.write(buffer, 0, read);
    }

    sourceStream.close();
    destStream.flush();
    destStream.close();
  }
}
