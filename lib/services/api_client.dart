import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marineguard/config/env.dart';

class CancelToken {
  bool _canceled = false;
  void cancel() => _canceled = true;
  bool get isCanceled => _canceled;
}

class ApiClient {
  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 25),
    int retries = 2,
    CancelToken? cancelToken,
  }) async {
    return _withRetry(
      () => _request(
        'GET',
        path,
        headers: headers,
        timeout: timeout,
        cancelToken: cancelToken,
      ),
      retries,
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 25),
    int retries = 2,
    CancelToken? cancelToken,
  }) async {
    return _withRetry(
      () => _request(
        'POST',
        path,
        headers: headers,
        body: body,
        timeout: timeout,
        cancelToken: cancelToken,
      ),
      retries,
    );
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    required Duration timeout,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl + path);
    final reqHeaders = {'Content-Type': 'application/json', ...?headers};

    if (cancelToken?.isCanceled == true) {
      throw Exception('Request canceled');
    }

    final future = method == 'GET'
        ? _client.get(uri, headers: reqHeaders)
        : _client.post(uri, headers: reqHeaders, body: body);

    final resp = await future.timeout(timeout);
    if (cancelToken?.isCanceled == true) {
      throw Exception('Request canceled');
    }
    return resp;
  }

  Future<http.Response> _withRetry(
    Future<http.Response> Function() fn,
    int retries,
  ) async {
    int attempt = 0;
    int delayMs = 400;
    while (true) {
      try {
        final resp = await fn();
        if (resp.statusCode >= 500 && attempt < retries) {
          await Future.delayed(Duration(milliseconds: delayMs));
          attempt++;
          delayMs *= 2;
          continue;
        }
        return resp;
      } on TimeoutException {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: delayMs));
          attempt++;
          delayMs *= 2;
          continue;
        }
        rethrow;
      } on http.ClientException {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: delayMs));
          attempt++;
          delayMs *= 2;
          continue;
        }
        rethrow;
      }
    }
  }
}
