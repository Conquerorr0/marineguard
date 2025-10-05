# Location & Date Screen

MarineGuard uygulamasının konum ve tarih seçim ekranı. Google Maps entegrasyonu ile kullanıcıların konum seçmesini ve tarih belirlemesini sağlar.

## Özellikler

### 🗺️ **Google Maps Entegrasyonu**
- **Interactive Map**: Kullanıcı pan/zoom yapabilir
- **Merkez Pin**: Haritanın merkezinde sabit pin (Marker yerine Stack içinde)
- **Kamera Animasyonu**: Seçilen konuma smooth geçiş
- **Pin Animasyonu**: Kamera idle sonrası bounce efekti

### 🔍 **Arama ve Autocomplete**
- **Google Places API**: Gerçek zamanlı yer önerileri
- **TypeAhead UI**: Yazdıkça öneriler çıkar
- **Türkiye Odaklı**: Ülke filtresi ile Türkçe sonuçlar
- **Koordinat Arama**: Manuel koordinat girişi desteği

### 📍 **Konum Yönetimi**
- **Reverse Geocoding**: Koordinatlardan adres bilgisi
- **Konum Onayı**: "Use this location" ile seçimi onaylama
- **Mevcut Konum**: Geolocator ile kullanıcı konumuna gitme
- **Fallback**: Hata durumunda "Dropped Pin" gösterimi

### 📅 **Tarih Seçimi**
- **Ay Seçimi**: 1-12 arası dropdown
- **Gün Seçimi**: 1-31 arası dropdown (aya göre dinamik)
- **Validasyon**: Geçersiz tarihler için hata mesajları
- **Dinamik Günler**: Seçilen aya göre gün sayısı kontrolü

### 🎨 **Material 3 Tasarım**
- **Renk Paleti**: Primary #0288D1, Secondary #F4C430, Background #F5F5F5
- **Typography**: Google Fonts Roboto
- **Accessibility**: Kontrast > 4.5:1, büyük dokunma alanları
- **Animations**: 150ms buton scale, 300ms pin bounce

## Teknik Detaylar

### Kullanılan Paketler
```yaml
google_maps_flutter: ^2.6.1    # Google Maps widget
geolocator: ^12.0.0            # Konum servisleri
geocoding: ^2.1.0              # Reverse geocoding
flutter_typeahead: ^5.2.0      # Autocomplete UI
http: ^1.2.0                   # Google Places REST API
google_fonts: ^6.2.1           # Roboto font
```

### API Entegrasyonu
- **Google Places API**: Autocomplete ve place details
- **Google Geocoding API**: Reverse geocoding
- **API Key**: `--dart-define=MAPS_API_KEY=...` ile geçilir

### Durum Yönetimi
```dart
// Ana state değişkenleri
LatLng _cameraLatLng;           // Harita kamera konumu
LatLng? _confirmedLatLng;       // Onaylanmış konum
String _confirmedPlaceName;     // Onaylanmış yer adı
int? _month, _day;              // Seçilen tarih
bool _isLocationConfirmed;      // Konum onay durumu
```

## Kullanım

### Temel Kullanım
```dart
// Ekranı aç
final result = await Navigator.push<LocationDateResult>(
  context,
  MaterialPageRoute(
    builder: (context) => const LocationDateScreen(),
  ),
);

// Sonucu işle
if (result != null) {
  print('Konum: ${result.lat}, ${result.lon}');
  print('Tarih: ${result.month}/${result.day}');
  print('Yer: ${result.placeName}');
}
```

### API Key Yapılandırması
```bash
# Development
flutter run --dart-define=MAPS_API_KEY=YOUR_API_KEY

# Production build
flutter build apk --dart-define=MAPS_API_KEY=YOUR_API_KEY
```

## Platform Kurulumu

### Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<application>
  <meta-data android:name="com.google.android.geo.API_KEY"
             android:value="${MAPS_API_KEY}" />
</application>
```

### iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>MarineGuard, size en yakın deniz hava durumu tahminleri sunabilmek için konum bilginize ihtiyaç duyar.</string>

<key>io.flutter.embedded_views_preview</key>
<true/>
```

```swift
// ios/Runner/AppDelegate.swift
import GoogleMaps

// API key'i ayarla
GMSServices.provideAPIKey(apiKey)
```

## Kullanıcı Akışı

1. **Arama**: Kullanıcı arama çubuğuna yer adı yazar
2. **Öneri Seçimi**: Autocomplete listesinden yer seçer
3. **Harita Animasyonu**: Harita seçilen konuma animate olur
4. **Pin Konumlandırma**: Merkez pin yeni konumu gösterir
5. **Konum Onayı**: "Use this location" ile konumu onaylar
6. **Tarih Seçimi**: Ay ve gün dropdown'larından seçim yapar
7. **Next**: Tüm koşullar sağlandığında sonraki adıma geçer

## Validasyon Kuralları

### Konum Validasyonu
- Koordinatlar geçerli aralıkta olmalı (lat: -90..90, lon: -180..180)
- Konum onaylanmış olmalı ("Use this location" tıklanmış)

### Tarih Validasyonu
- Ay: 1-12 arası olmalı
- Gün: 1-31 arası olmalı (seçilen aya göre üst sınır)
- Her ikisi de seçilmiş olmalı

### Next Buton Koşulları
```dart
bool canProceed = _isLocationConfirmed && 
                  _month != null && 
                  _day != null;
```

## Hata Yönetimi

### Ağ Hataları
- Places API hatalarında boş liste döndürülür
- Snackbar ile kullanıcıya bilgi verilir
- Fallback olarak "Dropped Pin" gösterilir

### İzin Hataları
- Konum izni reddedilirse snackbar uyarısı
- Ayarlara yönlendirme seçeneği
- Graceful degradation ile devam

### Validasyon Hataları
- Kırmızı hata metinleri (#D32F2F)
- Real-time validasyon
- Kullanıcı dostu hata mesajları

## Performans Optimizasyonları

### API Çağrıları
- Debounced arama (300ms gecikme)
- Cache mekanizması
- Error handling ile retry logic

### UI Optimizasyonları
- Lazy loading
- Efficient rebuilds
- Memory leak prevention

## Test

### Unit Testler
```bash
flutter test test/screens/location_date_screen_test.dart
```

### Widget Testler
- Temel render testleri
- User interaction testleri
- State management testleri

## Gelecek Geliştirmeler

- [ ] Offline harita desteği
- [ ] Favori konumlar
- [ ] Geçmiş aramalar
- [ ] Harita stilleri
- [ ] Çoklu dil desteği
- [ ] Accessibility iyileştirmeleri

## Sorun Giderme

### Yaygın Sorunlar
1. **API Key Hatası**: `--dart-define=MAPS_API_KEY=...` kontrol edin
2. **Konum İzni**: Android/iOS izin ayarlarını kontrol edin
3. **Harita Yüklenmiyor**: İnternet bağlantısını kontrol edin
4. **Autocomplete Çalışmıyor**: Places API quota'sını kontrol edin

### Debug Modu
```dart
// Debug bilgileri için
print('Camera: $_cameraLatLng');
print('Confirmed: $_confirmedLatLng');
print('Place: $_confirmedPlaceName');
```
