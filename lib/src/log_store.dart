import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';

class LogStore {
  LogStore(
    this.supportDirectory, {
    this.maxFileBytes = 5 * 1024 * 1024,
    this.retainedFiles = 5,
  });

  final Directory supportDirectory;
  final int maxFileBytes;
  final int retainedFiles;
  final Map<String, Future<void>> _queues = {};

  Directory get logDirectory =>
      Directory(p.join(supportDirectory.path, 'logs'));

  File _file(String serviceId, [int index = 0]) => File(
    p.join(
      logDirectory.path,
      index == 0 ? '$serviceId.log' : '$serviceId.log.$index',
    ),
  );

  Future<void> append(String serviceId, LogEntry entry) {
    final previous = _queues[serviceId] ?? Future.value();
    final next = previous.then((_) => _appendNow(serviceId, entry));
    _queues[serviceId] = next.catchError((_) {});
    return next;
  }

  Future<void> _appendNow(String serviceId, LogEntry entry) async {
    await logDirectory.create(recursive: true);
    final encoded = utf8.encode('${entry.serialize()}\n');
    final active = _file(serviceId);
    final currentLength = await active.exists() ? await active.length() : 0;
    if (currentLength + encoded.length > maxFileBytes) {
      await _rotate(serviceId);
    }
    await active.writeAsBytes(encoded, mode: FileMode.append, flush: true);
  }

  Future<void> _rotate(String serviceId) async {
    final oldest = _file(serviceId, retainedFiles - 1);
    if (await oldest.exists()) await oldest.delete();
    for (var index = retainedFiles - 2; index >= 1; index--) {
      final source = _file(serviceId, index);
      if (await source.exists()) {
        await source.rename(_file(serviceId, index + 1).path);
      }
    }
    final active = _file(serviceId);
    if (await active.exists()) await active.rename(_file(serviceId, 1).path);
  }

  Future<List<LogEntry>> readRecent(
    String serviceId, {
    int maxLines = 2000,
  }) async {
    final lines = Queue<String>();
    for (var index = retainedFiles - 1; index >= 0; index--) {
      final file = _file(serviceId, index);
      if (!await file.exists()) continue;
      await for (final line
          in file
              .openRead()
              .transform(const Utf8Decoder(allowMalformed: true))
              .transform(const LineSplitter())) {
        lines.add(line);
        if (lines.length > maxLines) lines.removeFirst();
      }
    }
    return lines.map(LogEntry.parse).whereType<LogEntry>().toList();
  }

  Future<void> clear(String serviceId) async {
    await (_queues[serviceId] ?? Future.value());
    for (var index = 0; index < retainedFiles; index++) {
      final file = _file(serviceId, index);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> close() async {
    await Future.wait(_queues.values);
  }
}
