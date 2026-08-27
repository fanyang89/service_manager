import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_manager/src/config_store.dart';
import 'package:service_manager/src/models.dart';

void main() {
  late Directory directory;
  late ConfigStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'service_manager_config_',
    );
    store = ConfigStore(directory);
  });

  tearDown(() => directory.delete(recursive: true));

  test('round-trips services and settings', () async {
    final service = ServiceConfig(
      id: 'service-1',
      name: 'Example',
      executable: '/bin/example',
      arguments: const ['--port', '8080'],
      environment: const {'MODE': 'test'},
      restartAutomatically: true,
    );
    const settings = AppSettings(localeCode: 'zh', launchAtLogin: true);

    await store.save([service], settings);
    final loaded = await store.load();

    expect(loaded.services.single.toJson(), service.toJson());
    expect(loaded.settings.toJson(), settings.toJson());
  });

  test('preserves a corrupt configuration file', () async {
    await directory.create(recursive: true);
    await File('${directory.path}/config.json').writeAsString('{broken');

    final loaded = await store.load();

    expect(loaded.services, isEmpty);
    expect(loaded.recoveredConfigPath, isNotNull);
    expect(await File(loaded.recoveredConfigPath!).exists(), isTrue);
  });
}
