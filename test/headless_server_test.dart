import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_manager/src/config_store.dart';
import 'package:service_manager/src/headless_server.dart';
import 'package:service_manager/src/log_store.dart';
import 'package:service_manager/src/service_controller.dart';

void main() {
  test('protects the API and manages a real process', () async {
    final directory = await Directory.systemTemp.createTemp(
      'service_manager_api_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final controller = ServiceController(
      configStore: ConfigStore(directory),
      logStore: LogStore(directory),
    );
    await controller.initialize();
    addTearDown(controller.dispose);
    final server = HeadlessServer(
      controller: controller,
      webRoot: Directory('${directory.path}/web'),
      port: 0,
    );
    await server.start();
    addTearDown(server.close);
    final base = Uri.parse('http://127.0.0.1:${server.boundPort}');

    final unauthorized = await _request(base.resolve('/api/state'));
    expect(unauthorized.statusCode, HttpStatus.unauthorized);

    final session = await _request(base.resolve('/api/session'));
    final token = (jsonDecode(session.body) as Map)['token'] as String;
    final headers = {'x-service-manager-token': token};
    final created = await _request(
      base.resolve('/api/services'),
      method: 'POST',
      headers: headers,
      body: jsonEncode({
        'name': 'Sleep',
        'executable': '/bin/sleep',
        'arguments': ['30'],
        'stopTimeoutSeconds': 1,
      }),
    );
    expect(created.statusCode, HttpStatus.created);
    final id = (jsonDecode(created.body) as Map)['id'] as String;

    final started = await _request(
      base.resolve('/api/services/$id/start'),
      method: 'POST',
      headers: headers,
    );
    expect((jsonDecode(started.body) as Map)['status'], 'running');

    final stopped = await _request(
      base.resolve('/api/services/$id/stop'),
      method: 'POST',
      headers: headers,
    );
    expect((jsonDecode(stopped.body) as Map)['status'], 'stopped');
  });
}

Future<({int statusCode, String body})> _request(
  Uri uri, {
  String method = 'GET',
  Map<String, String> headers = const {},
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }
    final response = await request.close();
    return (
      statusCode: response.statusCode,
      body: await utf8.decoder.bind(response).join(),
    );
  } finally {
    client.close();
  }
}
