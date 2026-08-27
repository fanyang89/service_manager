import 'dart:convert';
import 'dart:math';

enum ServiceStatus { stopped, starting, running, stopping, restarting, failed }

enum LogSource { stdout, stderr, manager }

String createServiceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(12, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

class ServiceConfig {
  const ServiceConfig({
    required this.id,
    required this.name,
    required this.executable,
    this.arguments = const [],
    this.workingDirectory = '',
    this.environment = const {},
    this.stopExecutable = '',
    this.stopArguments = const [],
    this.startAutomatically = false,
    this.restartAutomatically = false,
    this.stopTimeoutSeconds = 10,
  });

  final String id;
  final String name;
  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final Map<String, String> environment;
  final String stopExecutable;
  final List<String> stopArguments;
  final bool startAutomatically;
  final bool restartAutomatically;
  final int stopTimeoutSeconds;

  ServiceConfig copyWith({
    String? name,
    String? executable,
    List<String>? arguments,
    String? workingDirectory,
    Map<String, String>? environment,
    String? stopExecutable,
    List<String>? stopArguments,
    bool? startAutomatically,
    bool? restartAutomatically,
    int? stopTimeoutSeconds,
  }) {
    return ServiceConfig(
      id: id,
      name: name ?? this.name,
      executable: executable ?? this.executable,
      arguments: arguments ?? this.arguments,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      environment: environment ?? this.environment,
      stopExecutable: stopExecutable ?? this.stopExecutable,
      stopArguments: stopArguments ?? this.stopArguments,
      startAutomatically: startAutomatically ?? this.startAutomatically,
      restartAutomatically: restartAutomatically ?? this.restartAutomatically,
      stopTimeoutSeconds: stopTimeoutSeconds ?? this.stopTimeoutSeconds,
    );
  }

  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    final environment = (json['environment'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
    return ServiceConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      executable: json['executable'] as String,
      arguments: List<String>.from(json['arguments'] as List? ?? const []),
      workingDirectory: json['workingDirectory'] as String? ?? '',
      environment: environment,
      stopExecutable: json['stopExecutable'] as String? ?? '',
      stopArguments: List<String>.from(
        json['stopArguments'] as List? ?? const [],
      ),
      startAutomatically: json['startAutomatically'] as bool? ?? false,
      restartAutomatically: json['restartAutomatically'] as bool? ?? false,
      stopTimeoutSeconds:
          (json['stopTimeoutSeconds'] as num?)?.toInt().clamp(1, 300) ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'executable': executable,
    'arguments': arguments,
    'workingDirectory': workingDirectory,
    'environment': environment,
    'stopExecutable': stopExecutable,
    'stopArguments': stopArguments,
    'startAutomatically': startAutomatically,
    'restartAutomatically': restartAutomatically,
    'stopTimeoutSeconds': stopTimeoutSeconds,
  };
}

class AppSettings {
  const AppSettings({this.localeCode, this.launchAtLogin = false});

  final String? localeCode;
  final bool launchAtLogin;

  AppSettings copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? launchAtLogin,
  }) {
    return AppSettings(
      localeCode: clearLocale ? null : localeCode ?? this.localeCode,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    localeCode: json['localeCode'] as String?,
    launchAtLogin: json['launchAtLogin'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'localeCode': localeCode,
    'launchAtLogin': launchAtLogin,
  };
}

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.source,
    required this.message,
  });

  final DateTime timestamp;
  final LogSource source;
  final String message;

  String serialize() =>
      '${timestamp.toUtc().toIso8601String()}\t${source.name}\t${message.replaceAll('\n', r'\n')}';

  static LogEntry? parse(String line) {
    final first = line.indexOf('\t');
    final second = first < 0 ? -1 : line.indexOf('\t', first + 1);
    if (first < 0 || second < 0) return null;
    final timestamp = DateTime.tryParse(line.substring(0, first));
    final source = LogSource.values
        .where((value) => value.name == line.substring(first + 1, second))
        .firstOrNull;
    if (timestamp == null || source == null) return null;
    return LogEntry(
      timestamp: timestamp.toLocal(),
      source: source,
      message: line.substring(second + 1).replaceAll(r'\n', '\n'),
    );
  }
}
