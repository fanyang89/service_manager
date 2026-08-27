import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_manager/src/app.dart';
import 'package:service_manager/src/config_store.dart';
import 'package:service_manager/src/log_store.dart';
import 'package:service_manager/src/service_controller.dart';

void main() {
  testWidgets('shows the empty service state', (tester) async {
    late Directory directory;
    late ServiceController controller;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('service_manager_');
      controller = ServiceController(
        configStore: ConfigStore(directory),
        logStore: LogStore(directory),
      );
      await controller.initialize();
    });
    addTearDown(() => directory.delete(recursive: true));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ServiceManagerApp(
        controller: controller,
        onSetLaunchAtLogin: (_) async {},
      ),
    );
    await tester.pump();

    expect(find.text('No services yet'), findsOneWidget);
    expect(find.text('Add service'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
