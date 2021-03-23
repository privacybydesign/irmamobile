import 'dart:async';
import 'dart:convert';
import 'dart:io';

StreamSubscription sigintSubscription;
Process irmaServer, flutter;

Future<void> main(List<String> args) async {
  // Move regular configuration to temp dir
  final tempPath = Directory.systemTemp.createTempSync().path;
  final tempDir = Directory('irma_configuration').renameSync(tempPath);
  final configDir = Directory('irma_configuration');
  configDir.createSync();

  // Register sigint listener to nicely kill the tests when requested.
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
    clean(configDir, tempDir);
    exit(1);
  });

  try {
    await startTests(args, configDir, tempDir);
  } finally {
    clean(configDir, tempDir);
  }
}

Future<void> startTests(List<String> args, Directory configDir, Directory recoveryConfigDir) async {
  print('Loading test configuration...');
  print('Configuration in ${configDir.path} will be restored on completion automatically.');
  print('In case this fails, the configuration can be recovered from ${recoveryConfigDir.path}');

  // Remain irma-demo configuration from production config if present.
  recoveryConfigDir
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
    schemePath = schemePath.replaceFirst(configDir.path, recoveryConfigDir.path);
    final schemeDir = Directory(schemePath);
    schemeDir.copy(Directory([configDir.path, schemeDir.dirName].join(Platform.pathSeparator)));
  }

  print('Starting IRMA server...');
  irmaServer = await Process.start('irma', ['server', '--url=http://localhost:port']);
  final outputStream = irmaServer.stderr.asBroadcastStream(); // IRMA server only writes to stderr.
  outputStream.pipe(stderr);
  await outputStream.transform(utf8.decoder).firstWhere((line) => line.contains('Server listening at :8088'));

  print('Starting Flutter tests...');
  final flutterTool = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final appTestPath = ['test_driver', 'app.dart'].join(Platform.pathSeparator);
  flutter = await Process.start(flutterTool, ['drive', '--target=$appTestPath', ...args],
      mode: ProcessStartMode.inheritStdio);
  await flutter.exitCode;
}

void clean(Directory configDir, Directory recoveryConfigDir) {
  sigintSubscription?.cancel();
  flutter?.kill();
  irmaServer?.kill();

  print('\nRestoring irma_configuration...');
  // Wait a seconds to make sure all resources are released by child processes on sigint.
  sleep(const Duration(seconds: 1));
  configDir.deleteSync(recursive: true);
  recoveryConfigDir.renameSync(configDir.path);
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
