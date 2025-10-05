import 'dart:convert';
import 'package:marineguard/services/api_client.dart';

class EventsApi {
  final ApiClient _client;
  EventsApi(this._client);

  Future<List<String>> getEvents({CancelToken? cancelToken}) async {
    final resp = await _client.get(
      '/events',
      cancelToken: cancelToken,
      timeout: const Duration(seconds: 20),
      retries: 2,
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final list = (data as List).map((e) => e.toString()).toList();
      return list;
    }
    if (resp.statusCode >= 400 && resp.statusCode < 500) {
      throw EventsApiException('Geçersiz istek (${resp.statusCode})');
    }
    throw EventsApiException('Sunucu hatası (${resp.statusCode})');
  }
}

class EventsApiException implements Exception {
  final String message;
  EventsApiException(this.message);
  @override
  String toString() => message;
}
