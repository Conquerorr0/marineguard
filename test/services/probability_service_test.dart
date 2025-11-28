import 'package:flutter_test/flutter_test.dart';
import 'package:marineguard/services/probability_service.dart';

void main() {
  late ProbabilityService service;

  setUp(() {
    // Her testten önce yeni bir servis instance'ı oluştur
    service = ProbabilityService();
  });

  tearDown(() {
    // Servis instance'ını temizle
    service.dispose();
  });

  group('ProbabilityService - Validasyon Testleri', () {
    test('Geçersiz enlem değeri hata fırlatmalı', () async {
      expect(
        () => service.getProbabilities(
          -91, // Geçersiz enlem
          40.0,
          1,
          15,
          ['wind_high'],
        ),
        throwsA(isA<ProbabilityServiceException>()),
      );
    });

    test('Geçersiz boylam değeri hata fırlatmalı', () async {
      expect(
        () => service.getProbabilities(
          41.0,
          181, // Geçersiz boylam
          1,
          15,
          ['wind_high'],
        ),
        throwsA(isA<ProbabilityServiceException>()),
      );
    });

    test('Geçersiz ay değeri hata fırlatmalı', () async {
      expect(
        () => service.getProbabilities(
          41.0,
          29.0,
          13, // Geçersiz ay
          15,
          ['wind_high'],
        ),
        throwsA(isA<ProbabilityServiceException>()),
      );
    });

    test('Geçersiz gün değeri hata fırlatmalı', () async {
      expect(
        () => service.getProbabilities(
          41.0,
          29.0,
          1,
          32, // Geçersiz gün
          ['wind_high'],
        ),
        throwsA(isA<ProbabilityServiceException>()),
      );
    });

    test('Boş events listesi hata fırlatmalı', () async {
      expect(
        () => service.getProbabilities(
          41.0,
          29.0,
          1,
          15,
          [], // Boş liste
        ),
        throwsA(isA<ProbabilityServiceException>()),
      );
    });

    test('Geçersiz event türü hata fırlatmalı', () async {
      expect(
        () => service.getProbabilities(
          41.0,
          29.0,
          1,
          15,
          ['invalid_event'], // Geçersiz event
        ),
        throwsA(isA<ProbabilityServiceException>()),
      );
    });

    test('Geçerli parametrelerle hata fırlatmamalı (validasyon)', () {
      // Validasyon geçmeli, network hatası olabilir ama validasyon hatası olmamalı
      expect(
        () => service.getProbabilities(
          41.0,
          29.0,
          6,
          15,
          ['wind_high', 'rain_high'],
          {'rain_high': 15.0},
        ),
        isNot(
          throwsA(
            predicate(
              (e) =>
                  e is ProbabilityServiceException &&
                  (e.message.contains('Enlem') ||
                      e.message.contains('Boylam') ||
                      e.message.contains('Ay') ||
                      e.message.contains('Gün') ||
                      e.message.contains('Geçersiz olay')),
            ),
          ),
        ),
      );
    });
  });

  group('ProbabilityService - Valid Events', () {
    test('Tüm geçerli event türleri listelenmiş olmalı', () {
      final validEvents = ProbabilityService.validEvents;

      expect(validEvents, contains('wind_high'));
      expect(validEvents, contains('rain_high'));
      expect(validEvents, contains('wave_high'));
      expect(validEvents, contains('storm_high'));
      expect(validEvents, contains('fog_low'));
      expect(validEvents, contains('sst_high'));
      expect(validEvents, contains('current_strong'));
      expect(validEvents, contains('tide_high'));
      expect(validEvents, contains('ssha_high'));

      expect(validEvents.length, equals(9));
    });
  });

  group('ProbabilityServiceException', () {
    test('Exception mesajı doğru formatlanmalı', () {
      final exception = ProbabilityServiceException(
        'Test hatası',
        statusCode: 400,
      );

      expect(exception.toString(), contains('400'));
      expect(exception.toString(), contains('Test hatası'));
    });

    test('User message durum koduna göre özelleştirilmeli', () {
      final timeoutException = ProbabilityServiceException(
        'Timeout',
        statusCode: 408,
      );
      expect(timeoutException.userMessage, contains('zaman aşımı'));

      final serverException = ProbabilityServiceException(
        'Server error',
        statusCode: 500,
      );
      expect(serverException.userMessage, contains('Sunucu hatası'));

      final badRequestException = ProbabilityServiceException(
        'Bad request',
        statusCode: 400,
      );
      expect(badRequestException.userMessage, contains('Geçersiz istek'));

      final notFoundException = ProbabilityServiceException(
        'Not found',
        statusCode: 404,
      );
      expect(notFoundException.userMessage, contains('bulunamadı'));
    });
  });
}
