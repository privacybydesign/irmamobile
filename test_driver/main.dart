import 'dart:async';
import 'dart:io';

StreamSubscription sigintSubscription;
StreamSubscription irmaServerSubscription;

Future<void> main(List<String> args) async {
  final tempDir = Directory.systemTemp.createTempSync();
  final prodConfigDir = Directory('irma_configuration').renameSync(tempDir.path);
  final testConfigDir = Directory('irma_configuration');
  testConfigDir.createSync();

  // Register sigint listener to handle clean-up.
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
    clean(testConfigDir, prodConfigDir);
    exit(1);
  });

  // Remain irma-demo configuration from production config if present.
  prodConfigDir.listSync().where((entity) => entity.path.endsWith('/irma-demo')).forEach((entity) {
    if (entity is Directory) {
      copyDir(entity, Directory('${testConfigDir.path}/irma-demo'));
    }
  });

  if (Platform.environment.containsKey('SCHEME_URL')) {
    print('Downloading test configuration. This might take a while...');
    await Process.run('irma', ['scheme', 'download', testConfigDir.path, Platform.environment['SCHEME_URL']]);
  } else {
    // Use production config if no other config is specified.
    String schemePath = Platform.environment['SCHEME_PATH'];
    if (schemePath == null) {
      print('No test configuration specified, assuming ./irma_configuration/pbdf');
      schemePath = '${prodConfigDir.path}/pbdf';
    } else {
      // Take into account that configuration has been moved to temporary dir.
      schemePath = schemePath.replaceFirst(prodConfigDir.path, testConfigDir.path);
    }
    final schemeDir = Directory(schemePath);
    final schemeName = schemeDir.uri.pathSegments[schemeDir.uri.pathSegments.length - 2];
    copyDir(schemeDir, Directory('${testConfigDir.path}/$schemeName'));
  }

  print('Starting IRMA server...');
  final irmaServer = await Process.start('irma', ['server', '-s=${testConfigDir.path}'], runInShell: true);
  irmaServerSubscription = irmaServer.exitCode.asStream().listen((result) {
    print('IRMA server stopped unexpectedly:');
    irmaServer.stderr.pipe(stdout);
    // We cannot nicely kill the script here due to a bug in Dart.
    // https://github.com/google/process.dart/issues/42
  });

  print('Starting Flutter tests...\n');
  final flutter = await Process.start('flutter', ['drive', '--target=test_driver/app.dart', ...args],
      mode: ProcessStartMode.inheritStdio, runInShell: true);
  await flutter.exitCode;

  // Clean test configuration.
  clean(testConfigDir, prodConfigDir);
  irmaServer.kill();
}

void clean(Directory testConfigDir, Directory prodConfigDir) {
  sigintSubscription?.cancel();
  irmaServerSubscription?.cancel();

  print('\nRestoring irma_configuration...');
  testConfigDir.deleteSync(recursive: true);
  prodConfigDir.renameSync(testConfigDir.path);
  print('Restored.');
}

void copyDir(Directory src, Directory target) {
  for (final entity in src.listSync(recursive: true)) {
    // Deliberately don't support symbolic links, since this requires admin on Windows.
    if (entity is File) {
      final targetFile = File(entity.path.replaceFirst(src.path, target.path));
      targetFile.createSync(recursive: true);
      entity.copySync(targetFile.path);
    }
  }
}
