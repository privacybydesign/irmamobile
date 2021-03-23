import 'dart:async';
import 'dart:io';

StreamSubscription sigintSubscription;

Future<void> main(List<String> args) async {
  // Move regular configuration to temp dir
  final tempPath = Directory.systemTemp.createTempSync().path;
  final tempDir = Directory('irma_configuration').renameSync(tempPath);
  final configDir = Directory('irma_configuration');
  configDir.createSync();

  print('Loading test configuration...');
  print('Configuration in ${configDir.path} will be restored on completion automatically.');
  print('In case this fails, the configuration can be recovered from ${tempDir.path}');

  // Register sigint listener to handle clean-up.
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
    clean(configDir, tempDir);
    exit(1);
  });

  // Remain irma-demo configuration from production config if present.
  tempDir
      .listSync()
      .expand<Directory>((entity) => entity is Directory ? [entity] : [])
      .where((entity) => entity.dirName.startsWith('irma-demo'))
      .forEach((entity) => entity.copy(Directory([configDir.path, 'irma-demo'].join(Platform.pathSeparator))));

  if (Platform.environment.containsKey('SCHEME_URL')) {
    print('Downloading test configuration. This might take a while...');
    await Process.run('irma', ['scheme', 'download', configDir.path, Platform.environment['SCHEME_URL']]);
  } else {
    // Use production config if no other config is specified.
    String schemePath = Platform.environment['SCHEME_PATH'];
    if (schemePath == null) {
      schemePath = [configDir.path, 'pbdf'].join(Platform.pathSeparator);
      print('No test configuration specified, assuming $schemePath');
    }

    // Take into account that configuration has been moved to temporary dir.
    schemePath = schemePath.replaceFirst(configDir.path, tempPath);
    final schemeDir = Directory(schemePath);
    schemeDir.copy(Directory([configDir.path, schemeDir.dirName].join(Platform.pathSeparator)));
  }

  print('Starting Flutter tests...\n');
  final appTestPath = ['test_driver', 'app.dart'].join(Platform.pathSeparator);
  Process.start('flutter', ['drive', '--target=$appTestPath', ...args],
          mode: ProcessStartMode.inheritStdio, runInShell: true)
      .then((process) => process.exitCode)
      .whenComplete(() => clean(configDir, tempDir)); // Makes sure that errors are re-thrown after clean.
}

Future<void> clean(Directory testConfigDir, Directory prodConfigDir) async {
  sigintSubscription?.cancel();

  print('\nRestoring irma_configuration...');
  // Wait a seconds to make sure all resources are released by child processes on sigint.
  await Future.delayed(const Duration(seconds: 1));
  testConfigDir.deleteSync(recursive: true);
  prodConfigDir.renameSync(testConfigDir.path);
  print('Restored.');
}

extension DirectoryUtil on Directory {
  String get dirName => path.split(Platform.pathSeparator).last;

  void copy(Directory target) {
    for (final entity in listSync(recursive: true)) {
      // Deliberately don't support symbolic links, since this requires admin on Windows.
      if (entity is File) {
        final targetFile = File(entity.path.replaceFirst(path, target.path));
        targetFile.createSync(recursive: true);
        entity.copySync(targetFile.path);
      }
    }
  }
}
