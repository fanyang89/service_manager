import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_manager/src/config_store.dart';
import 'package:service_manager/src/log_store.dart';
import 'package:service_manager/src/models.dart';
import 'package:service_manager/src/service_controller.dart';

void main() {
  test('starts and stops a real foreground process', () async {
    final directory = await Directory.systemTemp.createTemp(
      'service_manager_run_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final controller = ServiceController(
      configStore: ConfigStore(directory),
      logStore: LogStore(directory),
    );
    await controller.initialize();
    addTearDown(controller.dispose);
    const config = ServiceConfig(
      id: 'sleep-service',
      name: 'Sleep',
      executable: '/bin/sleep',
      arguments: ['30'],
      stopTimeoutSeconds: 1,
    );
    await controller.addService(config);
    final service = controller.services.single;

    await controller.start(service);
    expect(service.status, ServiceStatus.running);
    expect(service.pid, isNotNull);

    await controller.stop(service);
    expect(service.status, ServiceStatus.stopped);
    expect(service.pid, isNull);
    expect(service.logs, isNotEmpty);
  });

  test('uses capped exponential restart delays', () {
    expect(ServiceController.restartDelay(0), const Duration(seconds: 1));
    expect(ServiceController.restartDelay(4), const Duration(seconds: 16));
    expect(ServiceController.restartDelay(99), const Duration(seconds: 30));
  });
}
