import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marineguard/screens/home_screen.dart';

/// MarineGuard Onboarding & İzin Ekranı
/// Material 3 tasarımı ile üç slaytlık tanıtım ve konum izni
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  /// Sonraki sayfaya geç
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _skipOnboarding();
    }
  }

  /// Onboarding'i atla ve ana ekrana geç
  void _skipOnboarding() async {
    await _saveOnboardingCompleted();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  /// Konum izni iste
  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      // Konum izni durumunu kontrol et
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // İzin kalıcı olarak reddedilmiş, ayarlara yönlendir
        await _showLocationPermissionDialog();
        await _saveLocationData(40.0, 30.0); // Fallback koordinatlar
      } else if (permission == LocationPermission.denied) {
        // İzin reddedilmiş
        await _saveLocationData(40.0, 30.0); // Fallback koordinatlar
      } else {
        // İzin verilmiş, konum al
        await _getCurrentLocation();
      }
    } catch (e) {
      // Hata durumunda fallback koordinatları kullan
      await _saveLocationData(40.0, 30.0);
    } finally {
      setState(() => _isLoading = false);
      _skipOnboarding();
    }
  }

  /// Mevcut konumu al
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _saveLocationData(position.latitude, position.longitude);
    } catch (e) {
      // Konum alınamazsa fallback kullan
      await _saveLocationData(40.0, 30.0);
    }
  }

  /// Konum verilerini kaydet
  Future<void> _saveLocationData(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_latitude', lat);
    await prefs.setDouble('user_longitude', lon);
  }

  /// Onboarding tamamlandı olarak işaretle
  Future<void> _saveOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  /// Konum izni dialog'u göster
  Future<void> _showLocationPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konum İzni Gerekli'),
          content: const Text(
            'MarineGuard, size en yakın deniz hava durumu tahminleri sunabilmek için konum bilginize ihtiyaç duyar. '
            'Ayarlardan konum iznini etkinleştirebilirsiniz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ayarlara Git'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Devam Et'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Buton animasyonu
  void _animateButton() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Üst kısım - Logo ve başlık
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo alanı
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0288D1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.anchor,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MarineGuard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),

            // PageView alanı
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomeSlide(),
                  _buildHowItWorksSlide(),
                  _buildSafetySlide(),
                ],
              ),
            ),

            // Alt kısım - Sayfa göstergesi ve butonlar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Sayfa göstergesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF0288D1)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Butonlar
                  if (_currentPage < 2) ...[
                    // Devam butonu
                    AnimatedBuilder(
                      animation: _buttonScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                _animateButton();
                                _nextPage();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Devam',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Son slayt butonları
                    Column(
                      children: [
                        // Konum İzni Ver butonu
                        AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          _animateButton();
                                          _requestLocationPermission();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0288D1),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Konum İzni Ver',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Daha Sonra butonu
                        AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _animateButton();
                                    _skipOnboarding();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Daha Sonra',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// İlk slayt - Hoş geldin
  Widget _buildWelcomeSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Deniz görseli
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFF0288D1)],
              ),
            ),
            child: Stack(
              children: [
                // Deniz ve gökyüzü
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE3F2FD), Color(0xFF0288D1)],
                        stops: [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
                // Tekne
                Positioned(
                  right: 40,
                  bottom: 60,
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_boat,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Dalgalar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01579B),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'MarineGuard\'a Hoş Geldiniz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'MarineGuard, balıkçılar ve denizciler için seçilen konum ve tarih için geçmiş yılların verilerini analiz ederek olasılık tabanlı hava ve deniz olayı tahminleri sunar.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Roboto',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// İkinci slayt - Nasıl çalışır
  Widget _buildHowItWorksSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Yelkenli görseli
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFF0288D1)],
              ),
            ),
            child: Stack(
              children: [
                // Deniz ve gökyüzü
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE3F2FD), Color(0xFF0288D1)],
                        stops: [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
                // Yelkenli
                Positioned(
                  right: 30,
                  bottom: 50,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.sailing,
                      color: Color(0xFF0288D1),
                      size: 32,
                    ),
                  ),
                ),
                // Dalgalar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01579B),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Nasıl Çalışır',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'MarineGuard, gelişmiş algoritmalar kullanarak deniz hava durumu olasılıklarını tahmin eder. Konumunuzu, tarihinizi ve istediğiniz olayları girmeniz, isteğe bağlı olarak daha hassas sonuçlar için eşikler belirlemeniz yeterlidir. Ardından, tahmininizi almak için \'Hesapla\'ya dokunun.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Roboto',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Üçüncü slayt - Güvenlik ve hız notu
  Widget _buildSafetySlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Güvenlik ikonu
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF4C430).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.security,
              color: Color(0xFFF4C430),
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Güvenlik ve Performans Notları',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'MarineGuard, bilinçli kararlar vermenize yardımcı olan bir araçtır, ancak iyi denizcilik becerilerinin yerini almaz. Her zaman resmi tahminleri kontrol edin ve kendi yargınızı kullanın. Performans, cihazınıza ve ağ bağlantınıza göre değişebilir. Uygulamayı sürekli geliştirmeye çalışıyoruz, ancak sabrınız için teşekkür ederiz.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Roboto',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
