import 'package:dio/dio.dart';

/// MarineGuard API'sine istekler yapmak için servis sınıfı
class ProbabilityService {
  static const String _baseUrl = 'https://marineguard-api.onrender.com';
  static const String _endpoint = '/calculate_probability';

  late final Dio _dio;
  bool _isLoading = false;

  /// Servisin yükleme durumunu kontrol eder
  bool get isLoading => _isLoading;

  ProbabilityService({String? earthdataToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Earthdata token interceptor ekle
    if (earthdataToken != null && earthdataToken.isNotEmpty) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $earthdataToken';
            return handler.next(options);
          },
        ),
      );
    }

    // Logging interceptor (debug için)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('📤 REQUEST[${options.method}] => PATH: ${options.path}');
          print('📤 DATA: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '📥 RESPONSE[${response.statusCode}] => DATA: ${response.data}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          print(
            '❌ ERROR[${error.response?.statusCode}] => MESSAGE: ${error.message}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Geçerli olay türleri
  static const List<String> validEvents = [
    'wind_high',
    'rain_high',
    'wave_high',
    'storm_high',
    'fog_low',
    'sst_high',
    'current_strong',
    'tide_high',
    'ssha_high',
  ];

  /// Hava durumu olasılıklarını hesaplar
  ///
  /// [lat]: Enlem (-90 ile 90 arası)
  /// [lon]: Boylam (-180 ile 180 arası)
  /// [month]: Ay (1-12 arası)
  /// [day]: Gün (1-31 arası)
  /// [events]: Hesaplanacak olay türleri listesi
  /// [thresholds]: Opsiyonel eşik değerleri (örn: {'rain_high': 15.0})
  ///
  /// Returns: Her olay için olasılık değerlerini içeren Map
  /// Throws: [ProbabilityServiceException] hata durumunda
  Future<Map<String, double>> getProbabilities(
    double lat,
    double lon,
    int month,
    int day,
    List<String> events, [
    Map<String, double>? thresholds,
  ]) async {
    // Validasyon
    _validateInput(lat, lon, month, day, events);

    _isLoading = true;

    try {
      final requestBody = {
        'lat': lat,
        'lon': lon,
        'month': month,
        'day': day,
        'events': events,
        if (thresholds != null && thresholds.isNotEmpty)
          'thresholds': thresholds,
      };

      final response = await _dio.post(_endpoint, data: requestBody);

      _isLoading = false;

      if (response.statusCode == 200) {
        return _parseResponse(response.data);
      } else {
        throw ProbabilityServiceException(
          'Beklenmeyen durum kodu: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _isLoading = false;
      throw _handleDioError(e);
    } catch (e) {
      _isLoading = false;
      throw ProbabilityServiceException(
        'Beklenmeyen hata: $e',
        originalError: e,
      );
    }
  }

  /// Input parametrelerini valide eder
  void _validateInput(
    double lat,
    double lon,
    int month,
    int day,
    List<String> events,
  ) {
    if (lat < -90 || lat > 90) {
      throw ProbabilityServiceException('Enlem -90 ile 90 arasında olmalıdır');
    }
    if (lon < -180 || lon > 180) {
      throw ProbabilityServiceException(
        'Boylam -180 ile 180 arasında olmalıdır',
      );
    }
    if (month < 1 || month > 12) {
      throw ProbabilityServiceException('Ay 1 ile 12 arasında olmalıdır');
    }
    if (day < 1 || day > 31) {
      throw ProbabilityServiceException('Gün 1 ile 31 arasında olmalıdır');
    }
    if (events.isEmpty) {
      throw ProbabilityServiceException('En az bir olay türü belirtilmelidir');
    }

    // Geçersiz event kontrolü
    final invalidEvents = events
        .where((e) => !validEvents.contains(e))
        .toList();
    if (invalidEvents.isNotEmpty) {
      throw ProbabilityServiceException(
        'Geçersiz olay türleri: ${invalidEvents.join(", ")}\n'
        'Geçerli türler: ${validEvents.join(", ")}',
      );
    }
  }

  /// Response'u Map<String, double> olarak parse eder
  Map<String, double> _parseResponse(dynamic data) {
    if (data is Map) {
      final result = <String, double>{};
      data.forEach((key, value) {
        if (value is num) {
          result[key.toString()] = value.toDouble();
        }
      });
      return result;
    } else {
      throw ProbabilityServiceException(
        'Geçersiz response formatı. Map bekleniyor, ${data.runtimeType} alındı',
      );
    }
  }

  /// DioException'ları işler ve anlamlı hatalar fırlatır
  ProbabilityServiceException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProbabilityServiceException(
          'İstek zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.',
          statusCode: 408,
          originalError: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['error'] ??
            e.response?.data?['message'] ??
            e.message;

        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ProbabilityServiceException(
            'İstemci hatası ($statusCode): $message',
            statusCode: statusCode,
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ProbabilityServiceException(
            'Sunucu hatası ($statusCode): $message',
            statusCode: statusCode,
            originalError: e,
          );
        }
        return ProbabilityServiceException(
          'HTTP hatası ($statusCode): $message',
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.cancel:
        return ProbabilityServiceException(
          'İstek iptal edildi',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return ProbabilityServiceException(
          'Bağlantı hatası. İnternet bağlantınızı kontrol edin.',
          originalError: e,
        );

      default:
        return ProbabilityServiceException(
          'Bilinmeyen hata: ${e.message}',
          originalError: e,
        );
    }
  }

  // Mock fonksiyon kaldırıldı

  /// Dio instance'ını kapat
  void dispose() {
    _dio.close();
  }
}

/// Servis ile ilgili hataları temsil eden özel exception sınıfı
class ProbabilityServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ProbabilityServiceException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ProbabilityServiceException [$statusCode]: $message';
    }
    return 'ProbabilityServiceException: $message';
  }

  /// Kullanıcıya gösterilecek hata mesajı
  String get userMessage {
    if (statusCode == 408) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else if (statusCode != null && statusCode! >= 500) {
      return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
    } else if (statusCode == 400) {
      return 'Geçersiz istek. Lütfen girdiğiniz bilgileri kontrol edin.';
    } else if (statusCode == 404) {
      return 'İstek yapılan kaynak bulunamadı.';
    }
    return message;
  }
}
