# ProbabilityService Kullanım Kılavuzu

## Genel Bakış

`ProbabilityService`, MarineGuard API'sine istekler göndererek deniz hava durumu olasılıklarını hesaplayan bir Flutter servis sınıfıdır. Dio kütüphanesi kullanarak HTTP istekleri yapar ve kapsamlı hata yönetimi sağlar.

## Özellikler

- ✅ Dio ile HTTP istekleri
- ✅ Otomatik timeout yönetimi (30 saniye)
- ✅ Earthdata token desteği (Authorization header)
- ✅ Kapsamlı input validasyonu
- ✅ DioException hata yakalama ve anlamlı hata mesajları
- ✅ Loading state yönetimi
- ✅ Mock data desteği (test için)
- ✅ Logging interceptor (debug için)
- ✅ 9 farklı olay türü desteği

## Kurulum

`pubspec.yaml` dosyanıza Dio paketini ekleyin:

```yaml
dependencies:
  dio: ^5.4.0
```

Paketleri yükleyin:

```bash
flutter pub get
```

## Temel Kullanım

### 1. Servis Instance'ı Oluşturma

```dart
import 'package:marineguard/services/probability_service.dart';

// Temel kullanım
final service = ProbabilityService();

// Earthdata token ile
final serviceWithToken = ProbabilityService(
  earthdataToken: 'your-earthdata-token-here',
);
```

### 2. Olasılık Hesaplama

```dart
try {
  final probabilities = await service.getProbabilities(
    41.0157,  // İstanbul enlemi
    28.9784,  // İstanbul boylamı
    6,        // Haziran
    15,       // 15. gün
    ['wind_high', 'rain_high', 'wave_high'],
  );
  
  // Sonuçları kullan
  print('Rüzgar olasılığı: ${probabilities['wind_high']}');
  print('Yağış olasılığı: ${probabilities['rain_high']}');
} on ProbabilityServiceException catch (e) {
  print('Hata: ${e.userMessage}');
}
```

### 3. Threshold Değerleriyle Kullanım

```dart
final probabilities = await service.getProbabilities(
  41.0157,
  28.9784,
  12,  // Aralık
  25,
  ['wind_high', 'rain_high', 'storm_high'],
  {
    'rain_high': 15.0,    // 15mm üzeri yağış
    'wind_high': 25.0,    // 25 knot üzeri rüzgar
  },
);
```

### 4. Tüm Event Türleriyle Kullanım

```dart
final probabilities = await service.getProbabilities(
  36.8969,
  30.7133,
  7,
  10,
  ProbabilityService.validEvents,  // Tüm event türleri
);
```

## Geçerli Event Türleri

Servis 9 farklı olay türünü destekler:

| Event Key | Açıklama |
|-----------|----------|
| `wind_high` | Yüksek rüzgar |
| `rain_high` | Yüksek yağış |
| `wave_high` | Yüksek dalga |
| `storm_high` | Fırtına |
| `fog_low` | Düşük görüş (sis) |
| `sst_high` | Yüksek deniz sıcaklığı |
| `current_strong` | Güçlü akıntı |
| `tide_high` | Yüksek gel-git |
| `ssha_high` | Yüksek deniz seviyesi |

## Hata Yönetimi

### Exception Yakalama

```dart
try {
  final result = await service.getProbabilities(...);
} on ProbabilityServiceException catch (e) {
  // Durum koduna göre işlem
  if (e.statusCode == 408) {
    print('Zaman aşımı: ${e.userMessage}');
  } else if (e.statusCode != null && e.statusCode! >= 500) {
    print('Sunucu hatası: ${e.userMessage}');
  } else {
    print('Hata: ${e.userMessage}');
  }
  
  // Orijinal hataya erişim
  print('Detay: ${e.originalError}');
}
```

### Hata Türleri

- **Timeout (408)**: Bağlantı zaman aşımı
- **400-499**: İstemci hataları (geçersiz parametreler, vb.)
- **500-599**: Sunucu hataları
- **Validasyon hataları**: Geçersiz koordinatlar, tarihler, event türleri

## Loading State Yönetimi

```dart
// Loading state kontrolü
if (service.isLoading) {
  print('İstek yapılıyor...');
}

// Flutter widget'ında kullanım
setState(() {
  _isLoading = service.isLoading;
});
```

## Mock Data (Test)

Test veya geliştirme sırasında gerçek API çağrısı yapmadan mock data kullanabilirsiniz:

```dart
final mockProbabilities = await service.getMockProbabilities(
  ['wind_high', 'rain_high', 'wave_high'],
);
```

## Flutter Widget'ında Kullanım

```dart
class WeatherProbabilityWidget extends StatefulWidget {
  @override
  State<WeatherProbabilityWidget> createState() => 
      _WeatherProbabilityWidgetState();
}

class _WeatherProbabilityWidgetState extends State<WeatherProbabilityWidget> {
  late final ProbabilityService _service;
  Map<String, double>? _probabilities;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ProbabilityService();
    _fetchProbabilities();
  }

  @override
  void dispose() {
    _service.dispose();  // Dio instance'ını kapat
    super.dispose();
  }

  Future<void> _fetchProbabilities() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _service.getProbabilities(
        41.0157, 28.9784, 6, 15,
        ['wind_high', 'rain_high'],
      );
      
      setState(() {
        _probabilities = result;
        _isLoading = false;
      });
    } on ProbabilityServiceException catch (e) {
      setState(() {
        _error = e.userMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircularProgressIndicator();
    }
    
    if (_error != null) {
      return Text('Hata: $_error');
    }
    
    if (_probabilities != null) {
      return ListView(
        children: _probabilities!.entries.map((entry) {
          return ListTile(
            title: Text(entry.key),
            trailing: Text('${(entry.value * 100).toStringAsFixed(1)}%'),
          );
        }).toList(),
      );
    }
    
    return Text('Veri yok');
  }
}
```

## Validasyon Kuralları

Servis otomatik olarak şu validasyonları yapar:

- **Enlem (lat)**: -90 ile 90 arasında olmalı
- **Boylam (lon)**: -180 ile 180 arasında olmalı
- **Ay (month)**: 1 ile 12 arasında olmalı
- **Gün (day)**: 1 ile 31 arasında olmalı
- **Events**: En az bir event belirtilmeli ve geçerli türlerden olmalı

## API Endpoint

- **Base URL**: `https://your-heroku-app.herokuapp.com`
- **Endpoint**: `/calculate_probability`
- **Method**: POST
- **Content-Type**: application/json

### Request Body

```json
{
  "lat": 41.0157,
  "lon": 28.9784,
  "month": 6,
  "day": 15,
  "events": ["wind_high", "rain_high"],
  "thresholds": {
    "rain_high": 15.0
  }
}
```

### Response

```json
{
  "wind_high": 0.25,
  "rain_high": 0.15
}
```

## Environment Variables

Earthdata token'ı environment variable olarak kullanmak için:

```dart
import 'dart:io';

final service = ProbabilityService(
  earthdataToken: Platform.environment['EARTHDATA_TOKEN'],
);
```

## Test Örnekleri

Test dosyasını çalıştırın:

```bash
flutter test test/services/probability_service_test.dart
```

## Örnek Uygulama

Tam çalışan örnek için `lib/examples/probability_service_example.dart` dosyasına bakın.

## İpuçları

1. **Dispose**: Widget dispose edilirken `service.dispose()` çağırın
2. **Error Handling**: Her zaman `ProbabilityServiceException` yakalayın
3. **Loading State**: UI'da loading göstergesi kullanın
4. **Mock Data**: Geliştirme sırasında mock data kullanın
5. **Token Security**: Earthdata token'ı güvenli bir şekilde saklayın

## Lisans

Bu proje MarineGuard projesi kapsamındadır.

