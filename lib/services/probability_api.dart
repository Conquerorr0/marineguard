import 'dart:convert';
import 'package:marineguard/models/api_models.dart';
import 'package:marineguard/services/api_client.dart';

class ProbabilityApi {
  final ApiClient _client;
  ProbabilityApi(this._client);

  Future<CalculateResponse> calculateProbability(
    CalculateRequest req, {
    CancelToken? cancelToken,
  }) async {
    final resp = await _client.post(
      '/calculate_probability',
      body: json.encode(req.toJson()),
      timeout: const Duration(seconds: 35),
      retries: 2,
      cancelToken: cancelToken,
    );

    if (resp.statusCode == 200) {
      final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
      return CalculateResponse.fromJson(jsonMap);
    }

    if (resp.statusCode == 400) {
      final err = json.decode(resp.body);
      throw ProbabilityApiException('Geçersiz istek', fields: err['fields']);
    }

    throw ProbabilityApiException('Sunucu hatası (${resp.statusCode})');
  }
}

class ProbabilityApiException implements Exception {
  final String message;
  final Map<String, dynamic>? fields;
  ProbabilityApiException(this.message, {this.fields});
  @override
  String toString() => message;
}
