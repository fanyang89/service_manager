import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_manager/src/log_store.dart';
import 'package:service_manager/src/models.dart';

void main() {
  test('rotates logs and reads recent entries in order', () async {
    final directory = await Directory.systemTemp.createTemp(
      'service_manager_log_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = LogStore(directory, maxFileBytes: 90, retainedFiles: 3);

    for (var index = 0; index < 12; index++) {
      await store.append(
        'service-1',
        LogEntry(
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, index),
          source: LogSource.stdout,
          message: 'message-$index',
        ),
      );
    }

    final entries = await store.readRecent('service-1', maxLines: 5);
    expect(entries.map((entry) => entry.message), [
      'message-7',
      'message-8',
      'message-9',
      'message-10',
      'message-11',
    ]);
  });
}
