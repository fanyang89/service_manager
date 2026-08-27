import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'config_store.dart';
import 'desktop_integration.dart';
import 'headless_server.dart';
import 'log_store.dart';
import 'service_controller.dart';

Future<void> bootstrap(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (!await _acquireSingleInstance()) {
    exit(0);
  }

  launchAtStartup.setup(
    appName: 'Service Manager',
    appPath: Platform.resolvedExecutable,
    packageName: 'io.github.fanyang89.serviceManager',
    args: const ['--hidden'],
  );

  final supportDirectory = await getApplicationSupportDirectory();
  final controller = ServiceController(
    configStore: ConfigStore(supportDirectory),
    logStore: LogStore(supportDirectory),
  );
  await controller.initialize();

  HeadlessServer? server;
  try {
    server = HeadlessServer(controller: controller, webRoot: _desktopWebRoot());
    await server.start();
  } on SocketException {
    server = null;
  }

  final appKey = GlobalKey<ServiceManagerAppState>();
  late final DesktopIntegration desktop;
  desktop = DesktopIntegration(
    controller: controller,
    onExitRequested: () async {
      await desktop.showWindow();
      await appKey.currentState?.confirmExit();
    },
  );
  await desktop.initialize();

  runApp(
    ServiceManagerApp(
      key: appKey,
      controller: controller,
      onSetLaunchAtLogin: desktop.setLaunchAtLogin,
      onOpenLogDirectory: desktop.openLogDirectory,
      onLocalizationsChanged: desktop.setLocalizations,
      onExit: () async {
        await server?.close();
        await desktop.exitApplication();
      },
    ),
  );

  const windowOptions = WindowOptions(
    size: Size(1100, 720),
    minimumSize: Size(720, 520),
    center: true,
    title: 'Service Manager',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (!arguments.contains('--hidden')) {
      await windowManager.show();
      await windowManager.focus();
    }
  });
  await controller.startAll(automaticOnly: true);
}

Directory _desktopWebRoot() {
  final bundled = Directory(
    p.join(File(Platform.resolvedExecutable).parent.path, 'web'),
  );
  return bundled.existsSync() ? bundled : Directory('build/web');
}

Future<bool> _acquireSingleInstance() async {
  const duplicateCheck = DuplicateCheckConfig(enableInDebugMode: true);
  const windowConfig = WindowConfig(windowTitle: 'Service Manager');
  const messages = EnMessageConfig();
  if (Platform.isWindows) {
    return FlutterAlone.instance.checkAndRun(
      config: FlutterAloneConfig.forWindows(
        windowsConfig: const DefaultWindowsMutexConfig(
          packageId: 'io.github.fanyang89.serviceManager',
          appName: 'Service Manager',
        ),
        duplicateCheckConfig: duplicateCheck,
        windowConfig: windowConfig,
        messageConfig: messages,
      ),
    );
  }
  if (Platform.isLinux) {
    return FlutterAlone.instance.checkAndRun(
      config: FlutterAloneConfig.forLinux(
        linuxConfig: LinuxConfig(lockFileName: 'service_manager.lock'),
        duplicateCheckConfig: duplicateCheck,
        windowConfig: windowConfig,
        messageConfig: messages,
      ),
    );
  }
  return FlutterAlone.instance.checkAndRun(
    config: FlutterAloneConfig.forMacOS(
      macOSConfig: MacOSConfig(lockFileName: 'service_manager.lock'),
      duplicateCheckConfig: duplicateCheck,
      windowConfig: windowConfig,
      messageConfig: messages,
    ),
  );
}
