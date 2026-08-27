import 'package:flutter/material.dart';

import 'app.dart';
import 'controller.dart';

Future<void> bootstrap(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = ServiceController();
  try {
    await controller.initialize();
  } catch (error) {
    runApp(_ConnectionError(error: error));
    return;
  }
  runApp(
    ServiceManagerApp(
      controller: controller,
      showLaunchAtLogin: false,
      onSetLaunchAtLogin: (enabled) => controller.updateSettings(
        controller.settings.copyWith(launchAtLogin: enabled),
      ),
    ),
  );
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 52),
                  const SizedBox(height: 20),
                  const Text(
                    'Service Manager backend is unavailable.',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  SelectableText('$error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
