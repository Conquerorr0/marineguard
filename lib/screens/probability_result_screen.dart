import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:marineguard/models/api_models.dart';
import 'package:marineguard/services/api_client.dart';
import 'package:marineguard/services/probability_api.dart';
import 'dart:math';
import 'package:marineguard/config/env.dart';

class ProbabilityResultScreen extends StatefulWidget {
  final LocationInfo location;
  final DateInfo date;
  final String eventKey;
  final Map<String, double>? thresholds;
  const ProbabilityResultScreen({
    super.key,
    required this.location,
    required this.date,
    required this.eventKey,
    this.thresholds,
  });

  @override
  State<ProbabilityResultScreen> createState() =>
      _ProbabilityResultScreenState();
}

class _ProbabilityResultScreenState extends State<ProbabilityResultScreen> {
  late final ApiClient _client;
  late final ProbabilityApi _api;
  final CancelToken _cancelToken = CancelToken();
  CalculateResponse? _resp;
  String? _error;
  bool _loading = true;
  Timer? _messageTimer;
  int _messageIndex = 0;
  static const _messages = [
    'Veriler çekiliyor...',
    'Olasılıklar hesaplanıyor...',
    'Sonuçlar yükleniyor...',
  ];

  String _animationForEvent(String key) {
    switch (key) {
      case 'sst_high':
        return 'lib/assets/animations/events/Hot Temperature.json';
      case 'wave_high':
        return 'lib/assets/animations/events/Waves.json';
      case 'ssha_high':
        return 'lib/assets/animations/events/Wave Progress.json';
      case 'current_strong':
        return 'lib/assets/animations/events/ocean.json';
      case 'wind_high':
        return 'lib/assets/animations/events/windy icon.json';
      case 'storm_high':
        return 'lib/assets/animations/events/Weather-storm.json';
      case 'rain_high':
        return 'lib/assets/animations/events/rain.json';
      case 'fog_low':
        return 'lib/assets/animations/events/sunny.json';
      default:
        return 'lib/assets/animations/events/ocean.json';
    }
  }

  String _displayNameForEvent(String key) {
    switch (key) {
      case 'current_strong':
        return 'Akıntı';
      case 'wave_high':
        return 'Yüksek Dalga';
      case 'sst_high':
        return 'Yüksek Deniz Sıcaklığı';
      case 'ssha_high':
        return 'Deniz Seviyesi Anomali';
      case 'storm_high':
        return 'Fırtına';
      case 'wind_high':
        return 'Kuvvetli Rüzgar';
      case 'fog_low':
        return 'Sis';
      case 'rain_high':
        return 'Yoğun Yağış';
      default:
        return key;
    }
  }

  Color _themeColorForEvent(String key) {
    switch (key) {
      case 'wave_high':
      case 'current_strong':
        return const Color(0xFF0288D1); // mavi
      case 'storm_high':
        return const Color(0xFFEF6C00); // turuncu
      case 'wind_high':
        return const Color(0xFF00796B); // teal
      case 'rain_high':
        return const Color(0xFF1565C0); // lacivert
      case 'fog_low':
        return const Color(0xFF757575); // gri
      case 'sst_high':
        return const Color(0xFFD32F2F); // kırmızı
      case 'ssha_high':
        return const Color(0xFF6A1B9A); // mor
      default:
        return const Color(0xFF0288D1);
    }
  }

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _api = ProbabilityApi(_client);
    _startRotatingMessage();
    _fetch();
  }

  void _startRotatingMessage() {
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _resp = null;
    });
    try {
      // Sunucu erişilebilir mi hızlı kontrol (5 sn timeout)
      try {
        await _client.get('/health', timeout: const Duration(seconds: 5));
      } catch (_) {
        throw Exception('Sunucuya ulaşılamıyor (/health başarısız).');
      }
      final req = CalculateRequest(
        location: widget.location,
        date: widget.date,
        events: [widget.eventKey],
        thresholds: widget.thresholds,
        // Ağır hesaplamayı azaltmak için varsayılan sentetik veri iste
        useSynthetic: true,
      );
      final r = await _api.calculateProbability(req, cancelToken: _cancelToken);
      if (!mounted) return;
      setState(() {
        _resp = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (ApiConfig.useMockFallback) {
        _useMockFallback(error: e.toString());
      } else {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _useMockFallback({String? error}) {
    final rnd = Random();
    final mockProb = (rnd.nextInt(100)) / 100.0; // 0.00 - 0.99
    final mock = CalculateResponse(
      success: true,
      location: widget.location,
      date: widget.date,
      probabilities: {widget.eventKey: mockProb},
      metadata: Metadata(
        totalEvents: 1,
        syntheticData: true,
        customThresholds: const [],
      ),
    );
    setState(() {
      _resp = mock;
      _loading = false;
      _error = null; // Hata mesajını temizle ki sonuç ekranı gösterilsin
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _cancelToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Probability',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_resp != null) return _buildResult();
    if (_error != null) return _buildError();
    return _buildLoading();
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Lottie.asset(
                _animationForEvent(widget.eventKey),
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _messages[_messageIndex],
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: OutlinedButton.icon(
                onPressed: () {
                  _cancelToken.cancel();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final isBadRequest = _error!.toLowerCase().contains('geçersiz istek');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBadRequest ? 'Form Hatası' : 'Sunucu Hatası',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.roboto(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _fetch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tekrar Dene'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Geri Dön'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _useMockFallback(error: _error),
                          child: const Text('Mock ile Devam Et'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _resp!;
    final prob = r.probabilities[widget.eventKey];
    final color = _themeColorForEvent(widget.eventKey);
    final title = _displayNameForEvent(widget.eventKey);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst özet kartı
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.12), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Lottie.asset(
                      _animationForEvent(widget.eventKey),
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lat: ${widget.location.lat.toStringAsFixed(4)}  |  Lon: ${widget.location.lon.toStringAsFixed(4)}',
                          style: GoogleFonts.roboto(color: Colors.black87),
                        ),
                        Text(
                          'Tarih: ${widget.date.month}/${widget.date.day}',
                          style: GoogleFonts.roboto(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (r.metadata.syntheticData)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Chip(
                  label: const Text(
                    'Uyarı: Sentetik veri kullanılmış olabilir',
                  ),
                  backgroundColor: Colors.orange[100],
                ),
              ),
            // Büyük yüzdelik gösterimi
            if (prob == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Veri yok/hesaplanamadı',
                    style: GoogleFonts.roboto(color: Colors.red[700]),
                  ),
                ),
              )
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Dairesel yüzde
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: prob,
                              strokeWidth: 10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _colorForProb(prob),
                              ),
                              backgroundColor: Colors.grey[200],
                            ),
                            Center(
                              child: Text(
                                '${(prob * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: prob,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _colorForProb(prob),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(_probabilityLabel(prob)),
                                  backgroundColor: _colorForProb(
                                    prob,
                                  ).withOpacity(0.12),
                                  labelStyle: GoogleFonts.roboto(
                                    color: _colorForProb(prob).withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Chip(
                                  label: const Text('Son 5 yıl verisi'),
                                  backgroundColor: Colors.blueGrey[50],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (r.metadata.customThresholds.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Özel Eşikler',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: r.metadata.customThresholds
                            .map((e) => Chip(label: Text(e)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Yakın geçmişe dayalı olasılık (son 5 yıl). Veriler istatistiksel modelleme ile hesaplanmıştır.',
                    style: GoogleFonts.roboto(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.place, color: Color(0xFF0288D1)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lat: ${widget.location.lat.toStringAsFixed(4)}  |  Lon: ${widget.location.lon.toStringAsFixed(4)}',
                  ),
                  Text('Tarih: ${widget.date.month}/${widget.date.day}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForProb(double v) {
    if (v < 0.3) return Colors.green;
    if (v < 0.6) return Colors.orange;
    return Colors.red;
  }

  String _probabilityLabel(double v) {
    if (v < 0.2) return 'Düşük';
    if (v < 0.4) return 'Orta-Düşük';
    if (v < 0.6) return 'Orta';
    if (v < 0.8) return 'Orta-Yüksek';
    return 'Yüksek';
  }
}
