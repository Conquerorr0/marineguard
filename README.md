# MarineGuard

MarineGuard, balıkçılar ve denizciler için seçilen konum ve tarih için geçmiş yılların verilerini analiz ederek olasılık tabanlı hava ve deniz olayı tahminleri sunan Flutter uygulamasıdır.

## Özellikler

### 🚀 Onboarding & İzin Yönetimi
- **Material 3 Tasarım**: Modern ve kullanıcı dostu arayüz
- **Üç Slaytlık Tanıtım**: Uygulama amacı, nasıl çalışır ve güvenlik notları
- **Konum İzni**: Geolocator ile otomatik konum alma
- **Fallback Koordinatlar**: İzin reddedilirse varsayılan koordinatlar (40.0, 30.0)
- **Animasyonlar**: 150ms buton scale animasyonu ve 300ms sayfa geçiş animasyonu

### 🌊 Hava Durumu Tahmin Servisi
- **ProbabilityService**: Dio ile HTTP istekleri
- **9 Farklı Olay Türü**: Rüzgar, yağış, dalga, fırtına, sis, deniz sıcaklığı, akıntı, gel-git, deniz seviyesi
- **Threshold Desteği**: Özelleştirilebilir eşik değerleri
- **Kapsamlı Hata Yönetimi**: Timeout, 400/500 durumları için özel hata mesajları
- **Mock Data**: Test için sahte veri desteği

### 🎨 Tasarım Sistemi
- **Renk Paleti**:
  - Primary: #0288D1 (Mavi)
  - Secondary: #F4C430 (Sarı)
  - Background: #F5F5F5 (Açık Gri)
- **Tipografi**: Roboto font ailesi
- **Material 3**: En güncel Material Design prensipleri

## Teknik Detaylar

### Kullanılan Paketler
```yaml
dependencies:
  dio: ^5.4.0                    # HTTP istekleri
  geolocator: ^10.1.0           # Konum servisleri
  permission_handler: ^11.0.1   # İzin yönetimi
  shared_preferences: ^2.2.2    # Yerel veri saklama
```

### Proje Yapısı
```
lib/
├── main.dart                    # Ana uygulama ve tema
├── screens/
│   ├── onboarding_screen.dart  # Onboarding & izin ekranı
│   └── home_screen.dart        # Ana ekran
├── services/
│   ├── probability_service.dart # API servis sınıfı
│   └── README.md               # Servis kullanım kılavuzu
└── examples/
    └── probability_service_example.dart # Servis örnek kullanımı
```

### API Endpoint
- **Base URL**: `https://your-heroku-app.herokuapp.com`
- **Endpoint**: `/calculate_probability`
- **Method**: POST
- **Content-Type**: application/json

#### Request Body
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

#### Response
```json
{
  "wind_high": 0.25,
  "rain_high": 0.15
}
```

## Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (3.8.1+)
- Dart SDK
- Android Studio / Xcode (platform geliştirme için)

### Adımlar
1. **Projeyi klonlayın**
   ```bash
   git clone <repository-url>
   cd marineguard
   ```

2. **Paketleri yükleyin**
   ```bash
   flutter pub get
   ```

3. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

### Platform İzinleri

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MarineGuard, size en yakın deniz hava durumu tahminleri sunabilmek için konum bilginize ihtiyaç duyar.</string>
```

## Kullanım

### Onboarding Akışı
1. **Splash Screen**: Uygulama başlatılır
2. **Slayt 1**: Hoş geldin mesajı ve uygulama amacı
3. **Slayt 2**: Nasıl çalışır açıklaması
4. **Slayt 3**: Güvenlik notları ve konum izni
5. **Ana Ekran**: ProbabilityService test ve kullanım

### ProbabilityService Kullanımı
```dart
// Servis instance'ı oluştur
final service = ProbabilityService();

// Olasılık hesapla
final probabilities = await service.getProbabilities(
  41.0157,  // Enlem
  28.9784,  // Boylam
  6,        // Ay
  15,       // Gün
  ['wind_high', 'rain_high'], // Olay türleri
  {'rain_high': 15.0},        // Threshold değerleri
);

// Sonuçları kullan
print('Rüzgar olasılığı: ${probabilities['wind_high']}');
```

## Test

### Unit Testler
```bash
flutter test
```

### Widget Testler
```bash
flutter test test/widget_test.dart
```

### Servis Testleri
```bash
flutter test test/services/probability_service_test.dart
```

## Geliştirme Notları

### Mock Data
Geliştirme sırasında gerçek API çağrısı yapmadan test etmek için:
```dart
final mockData = await service.getMockProbabilities(['wind_high', 'rain_high']);
```

### Hata Yönetimi
```dart
try {
  final result = await service.getProbabilities(...);
} on ProbabilityServiceException catch (e) {
  print('Hata: ${e.userMessage}');
}
```

### Loading State
```dart
if (service.isLoading) {
  // Loading göstergesi
}
```

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## İletişim

Proje hakkında sorularınız için issue açabilir veya iletişime geçebilirsiniz.

---

**Not**: Bu uygulama geliştirme aşamasındadır. Gerçek API entegrasyonu için backend servisinin hazır olması gerekmektedir.