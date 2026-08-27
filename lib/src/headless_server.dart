import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'models.dart';
import 'service_controller.dart';

class HeadlessServer {
  HeadlessServer({
    required this.controller,
    required this.webRoot,
    this.port = 47321,
  });

  final ServiceController controller;
  final Directory webRoot;
  final int port;

  HttpServer? _server;
  late final String _token = _createToken();

  int get boundPort => _server?.port ?? port;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen(_handleRequest);
  }

  Future<void> close() async {
    await _server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (!request.connectionInfo!.remoteAddress.isLoopback) {
        await _json(request.response, HttpStatus.forbidden, {
          'error': 'Only loopback connections are accepted.',
        });
        return;
      }

      if (request.uri.path == '/api/session' && request.method == 'GET') {
        await _json(request.response, HttpStatus.ok, {'token': _token});
        return;
      }

      if (request.uri.path.startsWith('/api/')) {
        if (request.headers.value('x-service-manager-token') != _token) {
          await _json(request.response, HttpStatus.unauthorized, {
            'error': 'Invalid session token.',
          });
          return;
        }
        await _handleApi(request);
        return;
      }

      await _serveStatic(request);
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      try {
        await _json(request.response, HttpStatus.internalServerError, {
          'error': error.toString(),
        });
      } catch (_) {
        await request.response.close();
      }
    }
  }

  Future<void> _handleApi(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    if (request.method == 'GET' && request.uri.path == '/api/state') {
      await _json(request.response, HttpStatus.ok, _stateJson());
      return;
    }

    if (request.method == 'PUT' && request.uri.path == '/api/settings') {
      final body = await _readJson(request);
      await controller.updateSettings(AppSettings.fromJson(body));
      await _json(request.response, HttpStatus.ok, _stateJson());
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/services') {
      final body = await _readJson(request);
      body['id'] = createServiceId();
      final config = ServiceConfig.fromJson(body);
      await controller.addService(config);
      await _json(
        request.response,
        HttpStatus.created,
        _serviceJson(controller.services.last),
      );
      return;
    }

    if (segments.length >= 3 &&
        segments[0] == 'api' &&
        segments[1] == 'services') {
      final record = _findRecord(segments[2]);
      if (record == null) {
        await _json(request.response, HttpStatus.notFound, {
          'error': 'Service not found.',
        });
        return;
      }

      if (request.method == 'GET' &&
          segments.length == 4 &&
          segments[3] == 'logs') {
        await _json(request.response, HttpStatus.ok, {
          'logs': record.logs.map(_logJson).toList(),
        });
        return;
      }

      if (request.method == 'PUT' && segments.length == 3) {
        final body = await _readJson(request);
        body['id'] = record.config.id;
        await controller.updateService(ServiceConfig.fromJson(body));
        await _json(request.response, HttpStatus.ok, _serviceJson(record));
        return;
      }

      if (request.method == 'DELETE' && segments.length == 3) {
        await controller.deleteService(record.config.id);
        await _json(request.response, HttpStatus.noContent, null);
        return;
      }

      if (request.method == 'POST' && segments.length == 4) {
        switch (segments[3]) {
          case 'start':
            await controller.start(record);
            break;
          case 'stop':
            await controller.stop(record);
            break;
          case 'restart':
            await controller.restart(record);
            break;
          case 'clear-logs':
            await controller.clearLogs(record);
            break;
          default:
            await _json(request.response, HttpStatus.notFound, {
              'error': 'Unknown service action.',
            });
            return;
        }
        await _json(request.response, HttpStatus.ok, _serviceJson(record));
        return;
      }
    }

    if (request.method == 'POST' && request.uri.path == '/api/start-all') {
      await controller.startAll();
      await _json(request.response, HttpStatus.ok, _stateJson());
      return;
    }
    if (request.method == 'POST' && request.uri.path == '/api/stop-all') {
      await controller.stopAll();
      await _json(request.response, HttpStatus.ok, _stateJson());
      return;
    }

    await _json(request.response, HttpStatus.notFound, {
      'error': 'Endpoint not found.',
    });
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('Expected JSON object.');
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> _stateJson() => {
    'settings': controller.settings.toJson(),
    'services': controller.services.map(_serviceJson).toList(),
    'recoveredConfigPath': controller.recoveredConfigPath,
  };

  Map<String, dynamic> _serviceJson(ServiceRecord record) => {
    ...record.config.toJson(),
    'status': record.status.name,
    'pid': record.pid,
    'exitCode': record.exitCode,
    'startedAt': record.startedAt?.toUtc().toIso8601String(),
    'restartAttempts': record.restartAttempts,
    'logs': record.logs.map(_logJson).toList(),
  };

  Map<String, dynamic> _logJson(LogEntry entry) => {
    'timestamp': entry.timestamp.toUtc().toIso8601String(),
    'source': entry.source.name,
    'message': entry.message,
  };

  ServiceRecord? _findRecord(String id) {
    for (final record in controller.services) {
      if (record.config.id == id) return record;
    }
    return null;
  }

  Future<void> _serveStatic(HttpRequest request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }

    if (!await webRoot.exists()) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..headers.contentType = ContentType.html
        ..write(
          '''<!doctype html><meta charset="utf-8">
<title>Service Manager</title>
<h1>Web build not found</h1>
<p>Run <code>flutter build web</code>, then restart the headless server.</p>''',
        );
      await request.response.close();
      return;
    }

    final root = p.normalize(p.absolute(webRoot.path));
    final requestedPath = request.uri.path == '/'
        ? 'index.html'
        : request.uri.path.substring(1);
    var filePath = p.normalize(p.join(root, requestedPath));
    if (!p.isWithin(root, filePath) && filePath != root) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    var file = File(filePath);
    if (!await file.exists() && p.extension(filePath).isEmpty) {
      filePath = p.join(root, 'index.html');
      file = File(filePath);
    }
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    request.response.headers.contentType = _contentType(file.path);
    request.response.headers.set('X-Content-Type-Options', 'nosniff');
    request.response.headers.set('X-Frame-Options', 'DENY');
    if (request.method == 'GET') {
      await request.response.addStream(file.openRead());
    }
    await request.response.close();
  }

  ContentType _contentType(String path) => switch (p.extension(path)) {
    '.html' => ContentType.html,
    '.js' => ContentType('application', 'javascript', charset: 'utf-8'),
    '.css' => ContentType('text', 'css', charset: 'utf-8'),
    '.json' => ContentType.json,
    '.png' => ContentType('image', 'png'),
    '.ico' => ContentType('image', 'x-icon'),
    '.svg' => ContentType('image', 'svg+xml'),
    '.wasm' => ContentType('application', 'wasm'),
    _ => ContentType.binary,
  };

  Future<void> _json(
    HttpResponse response,
    int statusCode,
    Object? value,
  ) async {
    response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store');
    if (value != null) response.write(jsonEncode(value));
    await response.close();
  }

  String _createToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
