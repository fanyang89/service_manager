import 'dart:async';
import 'dart:io';

import 'package:flutter_alone/flutter_alone.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import 'service_controller.dart';

class DesktopIntegration with TrayListener, WindowListener {
  DesktopIntegration({required this.controller, required this.onExitRequested});

  final ServiceController controller;
  final Future<void> Function() onExitRequested;

  AppLocalizations? _localizations;
  bool _initialized = false;
  bool _exiting = false;
  StreamSubscription<void>? _controllerSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    trayManager.addListener(this);
    windowManager.addListener(this);
    _controllerSubscription = controller.changes.listen((_) => _updateTray());
    await windowManager.setPreventClose(true);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/tray_icon.ico' : 'assets/tray_icon.png',
      isTemplate: Platform.isMacOS,
    );
    if (!Platform.isLinux) {
      await trayManager.setToolTip('Service Manager');
    }
    await _reconcileLaunchAtLogin();
  }

  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
    unawaited(_updateTray());
  }

  Future<void> _updateTray() async {
    final localizations = _localizations;
    if (localizations == null) return;
    if (!Platform.isLinux) {
      await trayManager.setToolTip(
        '${localizations.appName} - '
        '${localizations.runningCount(running: controller.runningCount)}',
      );
    }
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            label: localizations.open,
            onClick: (_) => unawaited(showWindow()),
          ),
          MenuItem.separator(),
          MenuItem(
            label: localizations.startAll,
            onClick: (_) => unawaited(controller.startAll()),
          ),
          MenuItem(
            label: localizations.stopAll,
            onClick: (_) => unawaited(controller.stopAll()),
          ),
          MenuItem.separator(),
          MenuItem(
            label: localizations.exit,
            onClick: (_) => unawaited(onExitRequested()),
          ),
        ],
      ),
    );
  }

  Future<void> _reconcileLaunchAtLogin() async {
    try {
      final enabled = await launchAtStartup.isEnabled();
      if (enabled == controller.settings.launchAtLogin) return;
      if (controller.settings.launchAtLogin) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (_) {
      // Login item errors are surfaced when the user changes the setting.
    }
  }

  Future<void> setLaunchAtLogin(bool enabled) async {
    final success = enabled
        ? await launchAtStartup.enable()
        : await launchAtStartup.disable();
    if (!success) throw StateError('Could not update launch at login.');
    await controller.updateSettings(
      controller.settings.copyWith(launchAtLogin: enabled),
    );
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }

  Future<void> openLogDirectory() async {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [controller.logDirectoryPath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [controller.logDirectoryPath]);
    } else {
      await Process.run('/usr/bin/open', [controller.logDirectoryPath]);
    }
  }

  Future<void> exitApplication() async {
    if (_exiting) return;
    _exiting = true;
    await controller.shutdown();
    await _controllerSubscription?.cancel();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await trayManager.destroy();
    await FlutterAlone.instance.dispose();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    if (!_exiting) unawaited(windowManager.hide());
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      unawaited(trayManager.popUpContextMenu());
    } else {
      unawaited(showWindow());
    }
  }

  void dispose() {
    unawaited(_controllerSubscription?.cancel());
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
