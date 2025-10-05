import 'package:flutter/material.dart';
import 'package:marineguard/services/probability_service.dart';

/// ProbabilityService kullanım örneği
class ProbabilityServiceExample extends StatefulWidget {
  const ProbabilityServiceExample({super.key});

  @override
  State<ProbabilityServiceExample> createState() =>
      _ProbabilityServiceExampleState();
}

class _ProbabilityServiceExampleState extends State<ProbabilityServiceExample> {
  late final ProbabilityService _service;
  Map<String, double>? _probabilities;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Servis instance'ı oluştur
    // Gerçek kullanımda Earthdata token environment variable'dan alınmalı
    _service = ProbabilityService(
      // earthdataToken: Platform.environment['EARTHDATA_TOKEN'],
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  /// Örnek 1: Temel kullanım
  Future<void> _fetchBasicProbabilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _probabilities = null;
    });

    try {
      final result = await _service.getProbabilities(
        41.0157, // İstanbul enlem
        28.9784, // İstanbul boylam
        6, // Haziran
        15, // 15. gün
        ['wind_high', 'rain_high', 'wave_high'],
      );

      setState(() {
        _probabilities = result;
        _isLoading = false;
      });
    } on ProbabilityServiceException catch (e) {
      setState(() {
        _errorMessage = e.userMessage;
        _isLoading = false;
      });
    }
  }

  /// Örnek 2: Threshold değerleriyle kullanım
  Future<void> _fetchProbabilitiesWithThresholds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _probabilities = null;
    });

    try {
      final result = await _service.getProbabilities(
        41.0157, // İstanbul enlem
        28.9784, // İstanbul boylam
        12, // Aralık
        25, // 25. gün
        ['wind_high', 'rain_high', 'storm_high', 'wave_high'],
        {
          'rain_high': 15.0, // 15mm üzeri yağış eşiği
          'wind_high': 25.0, // 25 knot üzeri rüzgar eşiği
        },
      );

      setState(() {
        _probabilities = result;
        _isLoading = false;
      });
    } on ProbabilityServiceException catch (e) {
      setState(() {
        _errorMessage = e.userMessage;
        _isLoading = false;
      });
    }
  }

  /// Örnek 3: Tüm event türleriyle kullanım
  Future<void> _fetchAllProbabilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _probabilities = null;
    });

    try {
      final result = await _service.getProbabilities(
        36.8969, // Antalya enlem
        30.7133, // Antalya boylam
        7, // Temmuz
        10, // 10. gün
        ProbabilityService.validEvents, // Tüm event türleri
      );

      setState(() {
        _probabilities = result;
        _isLoading = false;
      });
    } on ProbabilityServiceException catch (e) {
      setState(() {
        _errorMessage = e.userMessage;
        _isLoading = false;
      });
    }
  }

  /// Örnek 4: Mock data kullanımı (test için)
  Future<void> _fetchMockProbabilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _probabilities = null;
    });

    try {
      final result = await _service.getMockProbabilities([
        'wind_high',
        'rain_high',
        'wave_high',
        'storm_high',
      ]);

      setState(() {
        _probabilities = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Probability Service Örneği'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hava Durumu Olasılık Hesaplama',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Butonlar
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchBasicProbabilities,
              child: const Text('Temel Kullanım (İstanbul)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchProbabilitiesWithThresholds,
              child: const Text('Threshold ile (İstanbul - Kış)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchAllProbabilities,
              child: const Text('Tüm Events (Antalya)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchMockProbabilities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
              child: const Text('Mock Data (Test)'),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Sonuçlar
            Expanded(child: _buildResultWidget()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Yükleniyor...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Hata',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (_probabilities != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Olasılık Sonuçları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _probabilities!.length,
                  itemBuilder: (context, index) {
                    final entry = _probabilities!.entries.elementAt(index);
                    final percentage = (entry.value * 100).toStringAsFixed(1);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForProbability(entry.value),
                          child: Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(_getEventDisplayName(entry.key)),
                        trailing: SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: entry.value,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForProbability(entry.value),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'Bir buton seçerek veri çekin',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Color _getColorForProbability(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.6) return Colors.orange;
    return Colors.red;
  }

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
}
