import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:service_manager/src/config_store.dart';
import 'package:service_manager/src/headless_server.dart';
import 'package:service_manager/src/log_store.dart';
import 'package:service_manager/src/service_controller.dart';

Future<void> main(List<String> arguments) async {
  if (!arguments.contains('--headless')) {
    stderr.writeln(
      'Usage: dart run bin/service_manager.dart --headless '
      '[--port=47321] [--web-root=build/web] [--support-dir=PATH]',
    );
    exitCode = 64;
    return;
  }

  final port = int.tryParse(_option(arguments, 'port') ?? '') ?? 47321;
  final webRoot = _headlessWebRoot(arguments);
  final supportDirectory = Directory(
    _option(arguments, 'support-dir') ?? _defaultSupportDirectory(),
  );
  final controller = ServiceController(
    configStore: ConfigStore(supportDirectory),
    logStore: LogStore(supportDirectory),
  );
  await controller.initialize();

  final server = HeadlessServer(
    controller: controller,
    webRoot: webRoot,
    port: port,
  );
  await server.start();
  stdout.writeln(
    'Service Manager is listening on http://127.0.0.1:${server.boundPort}',
  );

  final done = Completer<void>();
  StreamSubscription<ProcessSignal>? sigint;
  StreamSubscription<ProcessSignal>? sigterm;
  sigint = ProcessSignal.sigint.watch().listen((_) {
    if (!done.isCompleted) done.complete();
  });
  if (!Platform.isWindows) {
    sigterm = ProcessSignal.sigterm.watch().listen((_) {
      if (!done.isCompleted) done.complete();
    });
  }
  await controller.startAll(automaticOnly: true);
  await done.future;
  await sigint.cancel();
  await sigterm?.cancel();
  await server.close();
  await controller.shutdown();
  await controller.dispose();
}

Directory _headlessWebRoot(List<String> arguments) {
  final configured = _option(arguments, 'web-root');
  if (configured != null) return Directory(configured);

  final executable = File(Platform.resolvedExecutable);
  final bundled = Directory(p.join(executable.parent.parent.path, 'web'));
  return bundled.existsSync() ? bundled : Directory('build/web');
}

String? _option(List<String> arguments, String name) {
  final prefix = '--$name=';
  for (final argument in arguments) {
    if (argument.startsWith(prefix)) return argument.substring(prefix.length);
  }
  return null;
}

String _defaultSupportDirectory() {
  if (Platform.isWindows) {
    final root =
        Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
    if (root == null) throw StateError('APPDATA is not set.');
    return p.join(root, 'Service Manager');
  }
  final home = Platform.environment['HOME'];
  if (home == null) throw StateError('HOME is not set.');
  if (Platform.isMacOS) {
    return p.join(home, 'Library', 'Application Support', 'Service Manager');
  }
  final root =
      Platform.environment['XDG_CONFIG_HOME'] ?? p.join(home, '.config');
  return p.join(root, 'service_manager');
}
