import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';

class ConfigSnapshot {
  const ConfigSnapshot({
    required this.services,
    required this.settings,
    this.recoveredConfigPath,
  });

  final List<ServiceConfig> services;
  final AppSettings settings;
  final String? recoveredConfigPath;
}

class ConfigStore {
  ConfigStore(this.supportDirectory);

  final Directory supportDirectory;

  File get _configFile => File(p.join(supportDirectory.path, 'config.json'));

  Future<ConfigSnapshot> load() async {
    await supportDirectory.create(recursive: true);
    if (!await _configFile.exists()) {
      return const ConfigSnapshot(services: [], settings: AppSettings());
    }

    try {
      final json = jsonDecode(await _configFile.readAsString());
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Configuration root must be an object.');
      }
      final services = (json['services'] as List? ?? const [])
          .map(
            (item) =>
                ServiceConfig.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final settings = AppSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
      );
      return ConfigSnapshot(services: services, settings: settings);
    } catch (_) {
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final recovered = File(
        p.join(supportDirectory.path, 'config.corrupt.$timestamp.json'),
      );
      await _configFile.rename(recovered.path);
      return ConfigSnapshot(
        services: const [],
        settings: const AppSettings(),
        recoveredConfigPath: recovered.path,
      );
    }
  }

  Future<void> save(List<ServiceConfig> services, AppSettings settings) async {
    await supportDirectory.create(recursive: true);
    final temporary = File('${_configFile.path}.tmp');
    final backup = File('${_configFile.path}.bak');
    final contents = const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'services': services.map((service) => service.toJson()).toList(),
      'settings': settings.toJson(),
    });
    await temporary.writeAsString(contents, flush: true);

    if (await backup.exists()) await backup.delete();
    if (await _configFile.exists()) await _configFile.rename(backup.path);
    try {
      await temporary.rename(_configFile.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (await backup.exists() && !await _configFile.exists()) {
        await backup.rename(_configFile.path);
      }
      rethrow;
    }
  }
}
