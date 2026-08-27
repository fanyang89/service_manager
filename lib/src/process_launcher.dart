import 'dart:io';

import 'models.dart';

abstract class ManagedProcess {
  int get pid;
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

class CommandResult {
  const CommandResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract class ProcessLauncher {
  Future<ManagedProcess> start(ServiceConfig config);

  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });

  Future<void> terminateTree(int pid, {required bool force});
}

class DartProcessLauncher implements ProcessLauncher {
  const DartProcessLauncher();

  @override
  Future<ManagedProcess> start(ServiceConfig config) async {
    final process = await Process.start(
      config.executable,
      config.arguments,
      workingDirectory: config.workingDirectory.isEmpty
          ? null
          : config.workingDirectory,
      environment: config.environment,
      includeParentEnvironment: true,
      runInShell: false,
      mode: ProcessStartMode.normal,
    );
    return _DartManagedProcess(process);
  }

  @override
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: true,
      runInShell: false,
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );
    return CommandResult(
      result.exitCode,
      result.stdout.toString(),
      result.stderr.toString(),
    );
  }

  @override
  Future<void> terminateTree(int pid, {required bool force}) async {
    if (Platform.isWindows) {
      final arguments = ['/PID', '$pid', '/T', if (force) '/F'];
      await Process.run('taskkill', arguments, runInShell: false);
      return;
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final descendants = await _descendantsOf(pid);
      final signal = force ? ProcessSignal.sigkill : ProcessSignal.sigterm;
      for (final childPid in descendants.reversed) {
        Process.killPid(childPid, signal);
      }
      Process.killPid(pid, signal);
    }
  }

  Future<List<int>> _descendantsOf(int parentPid) async {
    final result = await Process.run('/usr/bin/pgrep', ['-P', '$parentPid']);
    if (result.exitCode != 0) return const [];
    final children = result.stdout
        .toString()
        .split(RegExp(r'\s+'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final all = <int>[];
    for (final child in children) {
      all
        ..add(child)
        ..addAll(await _descendantsOf(child));
    }
    return all;
  }
}

class _DartManagedProcess implements ManagedProcess {
  const _DartManagedProcess(this.process);

  final Process process;

  @override
  int get pid => process.pid;

  @override
  Stream<List<int>> get stdout => process.stdout;

  @override
  Stream<List<int>> get stderr => process.stderr;

  @override
  Future<int> get exitCode => process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      process.kill(signal);
}
