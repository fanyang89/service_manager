import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'config_store.dart';
import 'log_store.dart';
import 'models.dart';
import 'process_launcher.dart';

class ServiceRecord {
  ServiceRecord(this.config, {List<LogEntry> logs = const []})
    : _logs = List.of(logs);

  ServiceConfig config;
  ServiceStatus status = ServiceStatus.stopped;
  int? pid;
  int? exitCode;
  DateTime? startedAt;
  int restartAttempts = 0;

  final List<LogEntry> _logs;
  final StreamController<void> _changes = StreamController.broadcast();
  UnmodifiableListView<LogEntry> get logs => UnmodifiableListView(_logs);
  Stream<void> get changes => _changes.stream;

  ManagedProcess? process;
  bool desiredRunning = false;
  Timer? restartTimer;
  Timer? stableTimer;
  Completer<void>? exitCompleter;
  final List<DateTime> failures = [];

  bool get isActive => switch (status) {
    ServiceStatus.starting ||
    ServiceStatus.running ||
    ServiceStatus.stopping ||
    ServiceStatus.restarting => true,
    ServiceStatus.stopped || ServiceStatus.failed => false,
  };

  void addLog(LogEntry entry) {
    _logs.add(entry);
    if (_logs.length > 2000) _logs.removeRange(0, _logs.length - 2000);
    _notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _notifyListeners();
  }

  void updateRuntime() => _notifyListeners();

  void _notifyListeners() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    restartTimer?.cancel();
    stableTimer?.cancel();
    await _changes.close();
  }
}

class ServiceController {
  ServiceController({
    ConfigStore? configStore,
    LogStore? logStore,
    this.processLauncher = const DartProcessLauncher(),
  }) : configStore =
           configStore ??
           (throw ArgumentError('configStore is required on desktop.')),
       logStore =
           logStore ??
           (throw ArgumentError('logStore is required on desktop.'));

  final ConfigStore configStore;
  final LogStore logStore;
  final ProcessLauncher processLauncher;
  final List<ServiceRecord> _services = [];
  final StreamController<void> _changes = StreamController.broadcast();

  AppSettings settings = const AppSettings();
  String? recoveredConfigPath;

  UnmodifiableListView<ServiceRecord> get services =>
      UnmodifiableListView(_services);
  Stream<void> get changes => _changes.stream;
  String get logDirectoryPath => logStore.logDirectory.path;
  int get runningCount => _services
      .where((service) => service.status == ServiceStatus.running)
      .length;

  Future<void> initialize() async {
    final snapshot = await configStore.load();
    settings = snapshot.settings;
    recoveredConfigPath = snapshot.recoveredConfigPath;
    for (final config in snapshot.services) {
      final logs = await logStore.readRecent(config.id);
      _services.add(ServiceRecord(config, logs: logs));
    }
    _notifyListeners();
  }

  Future<void> addService(ServiceConfig config) async {
    _services.add(ServiceRecord(config));
    await _save();
    _notifyListeners();
  }

  Future<void> updateService(ServiceConfig config) async {
    final record = _find(config.id);
    record.config = config;
    await _save();
    record.updateRuntime();
    _notifyListeners();
  }

  Future<void> deleteService(String id) async {
    final record = _find(id);
    await stop(record);
    _services.remove(record);
    await record.dispose();
    await logStore.clear(id);
    await _save();
    _notifyListeners();
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    await _save();
    _notifyListeners();
  }

  Future<void> start(ServiceRecord record) async {
    if (record.process != null || record.status == ServiceStatus.starting) {
      return;
    }
    record
      ..restartTimer?.cancel()
      ..desiredRunning = true
      ..status = ServiceStatus.starting
      ..exitCode = null;
    _notifyRuntime(record);

    try {
      if (!await File(record.config.executable).exists()) {
        throw ProcessException(
          record.config.executable,
          record.config.arguments,
          'Executable does not exist.',
        );
      }
      if (record.config.workingDirectory.isNotEmpty &&
          !await Directory(record.config.workingDirectory).exists()) {
        throw FileSystemException(
          'Working directory does not exist.',
          record.config.workingDirectory,
        );
      }

      await _managerLog(record, 'Starting ${record.config.executable}');
      final process = await processLauncher.start(record.config);
      record
        ..process = process
        ..pid = process.pid
        ..startedAt = DateTime.now()
        ..status = ServiceStatus.running
        ..exitCompleter = Completer<void>();
      record.stableTimer?.cancel();
      record.stableTimer = Timer(const Duration(seconds: 60), () {
        if (identical(record.process, process)) {
          record
            ..restartAttempts = 0
            ..failures.clear();
          _notifyRuntime(record);
        }
      });
      _consume(record, process.stdout, LogSource.stdout);
      _consume(record, process.stderr, LogSource.stderr);
      _notifyRuntime(record);
      unawaited(_watchExit(record, process));
    } catch (error) {
      record
        ..desiredRunning = false
        ..status = ServiceStatus.failed;
      await _managerLog(record, 'Failed to launch: $error');
      _notifyRuntime(record);
    }
  }

  void _consume(
    ServiceRecord record,
    Stream<List<int>> stream,
    LogSource source,
  ) {
    stream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) => _addLog(record, source, line));
  }

  Future<void> _watchExit(ServiceRecord record, ManagedProcess process) async {
    final code = await process.exitCode;
    if (!identical(record.process, process)) return;
    record.stableTimer?.cancel();
    final expected =
        !record.desiredRunning || record.status == ServiceStatus.stopping;
    record
      ..process = null
      ..pid = null
      ..exitCode = code;

    if (expected) {
      record
        ..status = ServiceStatus.stopped
        ..restartAttempts = 0;
      await _managerLog(record, 'Process stopped with code $code.');
    } else {
      await _managerLog(record, 'Process exited unexpectedly with code $code.');
      if (record.config.restartAutomatically && _canRestart(record)) {
        final delay = restartDelay(record.restartAttempts);
        record.restartAttempts++;
        record.status = ServiceStatus.restarting;
        await _managerLog(record, 'Restarting in ${delay.inSeconds}s.');
        record.restartTimer = Timer(delay, () => unawaited(start(record)));
      } else {
        record
          ..desiredRunning = false
          ..status = ServiceStatus.failed;
        if (record.config.restartAutomatically) {
          await _managerLog(record, 'Automatic restart limit reached.');
        }
      }
    }
    if (!(record.exitCompleter?.isCompleted ?? true)) {
      record.exitCompleter!.complete();
    }
    _notifyRuntime(record);
  }

  bool _canRestart(ServiceRecord record) {
    final now = DateTime.now();
    record.failures
      ..removeWhere((time) => now.difference(time) > const Duration(minutes: 5))
      ..add(now);
    return record.failures.length <= 5;
  }

  static Duration restartDelay(int attempt) {
    const seconds = [1, 2, 4, 8, 16, 30];
    return Duration(seconds: seconds[attempt.clamp(0, seconds.length - 1)]);
  }

  Future<void> stop(ServiceRecord record) async {
    record
      ..desiredRunning = false
      ..restartTimer?.cancel();
    final process = record.process;
    if (process == null) {
      record.status = ServiceStatus.stopped;
      _notifyRuntime(record);
      return;
    }

    record.status = ServiceStatus.stopping;
    _notifyRuntime(record);
    final timeout = Duration(seconds: record.config.stopTimeoutSeconds);

    if (record.config.stopExecutable.isNotEmpty) {
      await _managerLog(record, 'Running stop command.');
      try {
        final result = await processLauncher
            .run(
              record.config.stopExecutable,
              record.config.stopArguments,
              workingDirectory: record.config.workingDirectory.isEmpty
                  ? null
                  : record.config.workingDirectory,
              environment: record.config.environment,
            )
            .timeout(timeout);
        if (result.stdout.trim().isNotEmpty) {
          await _managerLog(record, result.stdout.trim());
        }
        if (result.stderr.trim().isNotEmpty) {
          await _addLog(record, LogSource.stderr, result.stderr.trim());
        }
      } catch (error) {
        await _managerLog(record, 'Stop command failed: $error');
      }
    }

    if (record.config.stopExecutable.isEmpty &&
        identical(record.process, process)) {
      await processLauncher.terminateTree(process.pid, force: false);
    }
    try {
      await record.exitCompleter?.future.timeout(timeout);
    } on TimeoutException {
      await _managerLog(
        record,
        'Stop timed out; forcing process tree to exit.',
      );
      await processLauncher.terminateTree(process.pid, force: true);
      process.kill(ProcessSignal.sigkill);
      try {
        await record.exitCompleter?.future.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        record.status = ServiceStatus.failed;
        _notifyRuntime(record);
      }
    }
  }

  Future<void> restart(ServiceRecord record) async {
    await stop(record);
    await start(record);
  }

  Future<void> startAll({bool automaticOnly = false}) async {
    for (final record in _services) {
      if (!automaticOnly || record.config.startAutomatically) {
        await start(record);
      }
    }
  }

  Future<void> stopAll() async {
    await Future.wait(_services.map(stop));
  }

  Future<void> clearLogs(ServiceRecord record) async {
    await logStore.clear(record.config.id);
    record.clearLogs();
  }

  Future<void> shutdown() async {
    await stopAll();
    await logStore.close();
  }

  Future<void> _managerLog(ServiceRecord record, String message) =>
      _addLog(record, LogSource.manager, message);

  Future<void> _addLog(
    ServiceRecord record,
    LogSource source,
    String message,
  ) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      source: source,
      message: message,
    );
    record.addLog(entry);
    await logStore.append(record.config.id, entry);
  }

  void _notifyRuntime(ServiceRecord record) {
    record.updateRuntime();
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_changes.isClosed) _changes.add(null);
  }

  ServiceRecord _find(String id) =>
      _services.firstWhere((record) => record.config.id == id);

  Future<void> _save() => configStore.save(
    _services.map((record) => record.config).toList(),
    settings,
  );

  Future<void> dispose() async {
    for (final service in _services) {
      await service.dispose();
    }
    await _changes.close();
  }
}
