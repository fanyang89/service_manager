// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:html';

import 'models.dart';

class ServiceRecord {
  ServiceRecord(this.config);

  ServiceConfig config;
  ServiceStatus status = ServiceStatus.stopped;
  int? pid;
  int? exitCode;
  DateTime? startedAt;
  int restartAttempts = 0;

  final List<LogEntry> _logs = [];
  final StreamController<void> _changes = StreamController.broadcast();
  UnmodifiableListView<LogEntry> get logs => UnmodifiableListView(_logs);
  Stream<void> get changes => _changes.stream;

  bool get isActive => switch (status) {
    ServiceStatus.starting ||
    ServiceStatus.running ||
    ServiceStatus.stopping ||
    ServiceStatus.restarting => true,
    ServiceStatus.stopped || ServiceStatus.failed => false,
  };

  void update(Map<String, dynamic> json) {
    config = ServiceConfig.fromJson(json);
    status = ServiceStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => ServiceStatus.failed,
    );
    pid = (json['pid'] as num?)?.toInt();
    exitCode = (json['exitCode'] as num?)?.toInt();
    startedAt = DateTime.tryParse(json['startedAt'] as String? ?? '')
        ?.toLocal();
    restartAttempts = (json['restartAttempts'] as num?)?.toInt() ?? 0;
    _logs
      ..clear()
      ..addAll(
        (json['logs'] as List? ?? const []).map((entry) {
          final item = Map<String, dynamic>.from(entry as Map);
          return LogEntry(
            timestamp: DateTime.parse(item['timestamp'] as String).toLocal(),
            source: LogSource.values.firstWhere(
              (value) => value.name == item['source'],
            ),
            message: item['message'] as String,
          );
        }),
      );
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class ServiceController {
  final List<ServiceRecord> _services = [];
  final StreamController<void> _changes = StreamController.broadcast();
  String? _token;
  Timer? _pollTimer;
  bool _refreshing = false;

  AppSettings settings = const AppSettings();
  String? recoveredConfigPath;

  UnmodifiableListView<ServiceRecord> get services =>
      UnmodifiableListView(_services);
  Stream<void> get changes => _changes.stream;
  String get logDirectoryPath => '';
  int get runningCount => _services
      .where((service) => service.status == ServiceStatus.running)
      .length;

  Future<void> initialize() async {
    final session = await _request('GET', '/api/session', authenticated: false);
    _token = session['token'] as String;
    await _refresh();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_refresh().catchError((_) {})),
    );
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final state = await _request('GET', '/api/state');
      settings = AppSettings.fromJson(
        Map<String, dynamic>.from(state['settings'] as Map),
      );
      recoveredConfigPath = state['recoveredConfigPath'] as String?;
      final seen = <String>{};
      for (final raw in state['services'] as List? ?? const []) {
        final json = Map<String, dynamic>.from(raw as Map);
        final id = json['id'] as String;
        seen.add(id);
        ServiceRecord? record;
        for (final candidate in _services) {
          if (candidate.config.id == id) {
            record = candidate;
            break;
          }
        }
        if (record == null) {
          record = ServiceRecord(ServiceConfig.fromJson(json));
          _services.add(record);
        }
        record.update(json);
      }
      final removed = _services
          .where((record) => !seen.contains(record.config.id))
          .toList();
      _services.removeWhere((record) => !seen.contains(record.config.id));
      for (final record in removed) {
        await record.dispose();
      }
      _changes.add(null);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> addService(ServiceConfig config) async {
    await _request('POST', '/api/services', body: config.toJson());
    await _refresh();
  }

  Future<void> updateService(ServiceConfig config) async {
    await _request(
      'PUT',
      '/api/services/${Uri.encodeComponent(config.id)}',
      body: config.toJson(),
    );
    await _refresh();
  }

  Future<void> deleteService(String id) async {
    await _request('DELETE', '/api/services/${Uri.encodeComponent(id)}');
    await _refresh();
  }

  Future<void> updateSettings(AppSettings value) async {
    await _request('PUT', '/api/settings', body: value.toJson());
    await _refresh();
  }

  Future<void> start(ServiceRecord record) => _action(record, 'start');
  Future<void> stop(ServiceRecord record) => _action(record, 'stop');
  Future<void> restart(ServiceRecord record) => _action(record, 'restart');

  Future<void> _action(ServiceRecord record, String action) async {
    await _request(
      'POST',
      '/api/services/${Uri.encodeComponent(record.config.id)}/$action',
    );
    await _refresh();
  }

  Future<void> startAll({bool automaticOnly = false}) async {
    if (automaticOnly) return;
    await _request('POST', '/api/start-all');
    await _refresh();
  }

  Future<void> stopAll() async {
    await _request('POST', '/api/stop-all');
    await _refresh();
  }

  Future<void> clearLogs(ServiceRecord record) async {
    await _action(record, 'clear-logs');
  }

  Future<void> shutdown() async {}

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (authenticated && _token != null) 'X-Service-Manager-Token': _token!,
    };
    final request = await HttpRequest.request(
      path,
      method: method,
      requestHeaders: headers,
      sendData: body == null ? null : jsonEncode(body),
    );
    if (request.status == null || request.status! >= 400) {
      throw StateError(
        request.responseText ?? 'Request failed with status ${request.status}.',
      );
    }
    if (request.status == 204 || request.responseText?.isEmpty == true) {
      return const {};
    }
    final decoded = jsonDecode(request.responseText ?? '{}');
    if (decoded is! Map) throw const FormatException('Expected JSON object.');
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> dispose() async {
    _pollTimer?.cancel();
    for (final service in _services) {
      await service.dispose();
    }
    await _changes.close();
  }
}
