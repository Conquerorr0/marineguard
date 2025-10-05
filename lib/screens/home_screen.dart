import 'package:flutter/material.dart';
import 'package:marineguard/services/probability_service.dart';
import 'package:marineguard/screens/location_date_screen.dart';
import 'package:marineguard/screens/event_selection_screen.dart';
import 'package:marineguard/models/location_date_result.dart';
import 'package:marineguard/models/api_models.dart';
import 'package:marineguard/screens/probability_result_screen.dart';

/// Ana ekran - MarineGuard uygulamasının ana sayfası
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProbabilityService _probabilityService;
  Map<String, double>? _probabilities;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _probabilityService = ProbabilityService();
  }

  @override
  void dispose() {
    _probabilityService.dispose();
    super.dispose();
  }

  // Mock test kaldırıldı

  /// Konum ve tarih seçim ekranına git
  Future<void> _goToLocationDateScreen() async {
    final result = await Navigator.push<LocationDateResult>(
      context,
      MaterialPageRoute(builder: (context) => const LocationDateScreen()),
    );

    if (result != null) {
      if (!mounted) return;
      // Konum/tarih tamamlandıktan sonra event kart ekranına geç
      final selectedEvent = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const EventSelectionScreen()),
      );
      if (selectedEvent != null && selectedEvent.isNotEmpty) {
        final loc = LocationInfo(lat: result.lat, lon: result.lon);
        final date = DateInfo(month: result.month, day: result.day);
        // ignore: use_build_context_synchronously
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProbabilityResultScreen(
              location: loc,
              date: date,
              eventKey: selectedEvent,
            ),
          ),
        );
      }
    }
  }

  /// Konum ve tarih seçim sonucunu göster
  void _showLocationDateResult(LocationDateResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Seçim Sonucu',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yer: ${result.placeName}'),
              const SizedBox(height: 8),
              Text('Enlem: ${result.lat.toStringAsFixed(6)}'),
              Text('Boylam: ${result.lon.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Ay: ${result.month}'),
              Text('Gün: ${result.day}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tamam',
                style: TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'MarineGuard',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Yardım dialog'u göster
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin kartı
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0288D1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.anchor,
                            color: Color(0xFF0288D1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoş Geldiniz!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Text(
                                'Deniz hava durumu tahminleri için hazır',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Konum ve tarih seçimi butonu
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konum ve Tarih Seçimi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Google Maps ile konum seçin ve tarih belirleyin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _goToLocationDateScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4C430),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Konum ve Tarih Seç',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Hızlı test kaldırıldı
            const SizedBox(height: 24),

            // Sonuç gösterimi kaldırıldı
            const SizedBox(height: 24),

            // API entegrasyon uyarısı kaldırıldı
          ],
        ),
      ),
    );
  }

  /// Olasılık değerine göre renk döndür
  Color _getColorForProbability(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.6) return Colors.orange;
    return Colors.red;
  }

  /// Event anahtarını Türkçe isme çevir
  String _getEventDisplayName(String eventKey) {
    const eventNames = {
      'wind_high': 'Yüksek Rüzgar',
      'rain_high': 'Yüksek Yağış',
      'wave_high': 'Yüksek Dalga',
      'storm_high': 'Fırtına',
      'fog_low': 'Düşük Görüş (Sis)',
      'sst_high': 'Yüksek Deniz Sıcaklığı',
      'current_strong': 'Güçlü Akıntı',
      'tide_high': 'Yüksek Gel-Git',
      'ssha_high': 'Yüksek Deniz Seviyesi',
    };
    return eventNames[eventKey] ?? eventKey;
  }

  /// Yardım dialog'u göster
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Yardım',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'MarineGuard, deniz hava durumu olasılık tahminleri sunan bir uygulamadır. '
            'Şu anda geliştirme aşamasındadır ve test verileri kullanmaktadır.\n\n'
            'Özellikler:\n'
            '• Konum bazlı tahminler\n'
            '• Geçmiş veri analizi\n'
            '• Olasılık tabanlı sonuçlar\n'
            '• 9 farklı hava olayı türü',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tamam',
                style: TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        );
      },
    );
  }
}
