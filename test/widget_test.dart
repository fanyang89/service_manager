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

    final context = tester.element(find.text('No services yet'));
    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'Noto Sans SC');
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme?.textTheme.bodyMedium?.fontFamily, 'Noto Sans SC');
    expect(find.text('No services yet'), findsOneWidget);
    expect(find.text('Add service'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Add service'));
    await tester.pumpAndSettle();

    expect(find.text('Basic settings'), findsOneWidget);
    expect(find.text('Environment'), findsNothing);

    final form = find.descendant(
      of: find.byType(Form),
      matching: find.byType(ListView),
    );
    await tester.drag(form, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.text('Advanced settings'), findsOneWidget);

    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();

    expect(find.text('Environment'), findsOneWidget);
    expect(find.text('Stop executable'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
