import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Yalnızca debug build'de her birlikte-api isteğini/yanıtını Xcode/Android
/// Studio konsoluna yazar — release'de hiçbir şey yapmaz.
///
/// `Authorization` başlığı KASITLI olarak loglanmıyor (token sızdırmamak
/// için); istek/yanıt gövdeleri (TC kimlik no, doğum tarihi dahil) debug
/// build'de görünür, bu normal — gerçek cihazda release ile dağıtılan
/// sürümde bu sınıf devre dışı.
class BirlikteApiLoggingClient extends http.BaseClient {
  BirlikteApiLoggingClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) return _inner.send(request);

    final body = request is http.Request && request.body.isNotEmpty
        ? request.body
        : null;
    debugPrint(
      '➡️ birlikte-api ${request.method} ${request.url}'
      '${body != null ? '\n$body' : ''}',
    );

    final stopwatch = Stopwatch()..start();
    final http.StreamedResponse streamed;
    try {
      streamed = await _inner.send(request);
    } catch (e) {
      debugPrint('⬅️ birlikte-api HATA ${request.method} ${request.url}: $e');
      rethrow;
    }

    final response = await http.Response.fromStream(streamed);
    stopwatch.stop();
    debugPrint(
      '⬅️ birlikte-api ${response.statusCode} ${request.method} '
      '${request.url} (${stopwatch.elapsedMilliseconds}ms)\n'
      '${_prettyOrRaw(response.body)}',
    );

    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  static String _prettyOrRaw(String body) {
    if (body.isEmpty) return '(boş gövde)';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }
}
