import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marineguard/models/place_suggestion.dart';
import 'package:marineguard/models/location_date_result.dart';
import 'package:marineguard/services/places_service.dart';

/// Konum ve tarih seçim ekranı
class LocationDateScreen extends StatefulWidget {
  const LocationDateScreen({super.key});

  @override
  State<LocationDateScreen> createState() => _LocationDateScreenState();
}

class _LocationDateScreenState extends State<LocationDateScreen>
    with TickerProviderStateMixin {
  // API Key
  static const String kMapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  // Services
  late final PlacesService _placesService;

  // Controllers
  late final TextEditingController _searchController;
  late final GoogleMapController? _mapController;
  late final AnimationController _pinAnimationController;
  late final Animation<double> _pinAnimation;

  // State variables
  LatLng _cameraLatLng = const LatLng(41.0157, 28.9784); // İstanbul default
  LatLng? _confirmedLatLng;
  String _confirmedPlaceName = 'Dropped Pin';
  int? _month;
  int? _day;
  bool _isLocationConfirmed = false;
  bool _isLoadingGeolocate = false;
  bool _isReverseGeocoding = false;
  bool _showManualCoordinates = false;
  String? _monthError;
  String? _dayError;
  String? _latError;
  String? _lonError;

  // Manual coordinate controllers
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(apiKey: kMapsApiKey);
    _searchController = TextEditingController();
    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pinAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pinAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _pinAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Arama önerilerini getir
  Future<List<PlaceSuggestion>> _getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final suggestions = await _placesService.autocomplete(query);
      return suggestions;
    } catch (e) {
      _showSnackBar('Arama hatası: $e');
      return [];
    }
  }

  /// Öneri seçildiğinde
  void _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _searchController.text = suggestion.description;

    try {
      final coordinates = await _placesService.getPlaceLatLng(
        suggestion.placeId,
      );
      final newLatLng = LatLng(
        coordinates['lat'] as double,
        coordinates['lng'] as double,
      );

      await _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));

      setState(() {
        _cameraLatLng = newLatLng;
      });
    } catch (e) {
      _showSnackBar('Konum bilgisi alınamadı: $e');
    }
  }

  /// Harita kamera hareketi durduğunda
  void _onCameraIdle() async {
    if (_mapController != null) {
      final position = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (position.northeast.latitude + position.southwest.latitude) / 2,
        (position.northeast.longitude + position.southwest.longitude) / 2,
      );

      setState(() {
        _cameraLatLng = center;
      });

      // Pin animasyonu
      _pinAnimationController.forward().then((_) {
        _pinAnimationController.reverse();
      });
    }
  }

  /// Mevcut konuma git
  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingGeolocate = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Konum izni kalıcı olarak reddedilmiş. Ayarlardan etkinleştirin.',
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        _showSnackBar('Konum izni reddedildi.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      await _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));

      setState(() {
        _cameraLatLng = newLatLng;
      });
    } catch (e) {
      _showSnackBar('Konum alınamadı: $e');
    } finally {
      setState(() => _isLoadingGeolocate = false);
    }
  }

  /// Onaylanmış konuma dön
  void _recenterToConfirmed() {
    if (_confirmedLatLng != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(_confirmedLatLng!));
    }
  }

  /// Konumu onayla
  Future<void> _confirmLocation() async {
    setState(() => _isReverseGeocoding = true);

    try {
      final address = await _placesService.getAddressFromCoordinates(
        _cameraLatLng.latitude,
        _cameraLatLng.longitude,
      );

      setState(() {
        _confirmedLatLng = _cameraLatLng;
        _confirmedPlaceName = address;
        _isLocationConfirmed = true;
      });
    } catch (e) {
      setState(() {
        _confirmedLatLng = _cameraLatLng;
        _confirmedPlaceName = 'Dropped Pin';
        _isLocationConfirmed = true;
      });
    } finally {
      setState(() => _isReverseGeocoding = false);
    }
  }

  /// Manuel koordinat girişi
  void _toggleManualCoordinates() {
    setState(() {
      _showManualCoordinates = !_showManualCoordinates;
      if (_showManualCoordinates) {
        _latController.text = _cameraLatLng.latitude.toStringAsFixed(6);
        _lonController.text = _cameraLatLng.longitude.toStringAsFixed(6);
      }
    });
  }

  /// Manuel koordinatları kaydet
  void _saveManualCoordinates() {
    final latText = _latController.text.trim();
    final lonText = _lonController.text.trim();

    setState(() {
      _latError = null;
      _lonError = null;
    });

    // Validasyon
    final lat = double.tryParse(latText);
    final lon = double.tryParse(lonText);

    if (lat == null || lat < -90 || lat > 90) {
      setState(() => _latError = 'Enlem -90 ile 90 arasında olmalıdır');
      return;
    }

    if (lon == null || lon < -180 || lon > 180) {
      setState(() => _lonError = 'Boylam -180 ile 180 arasında olmalıdır');
      return;
    }

    final newLatLng = LatLng(lat, lon);

    _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));

    setState(() {
      _cameraLatLng = newLatLng;
      _showManualCoordinates = false;
    });
  }

  /// Ay seçimi
  void _onMonthChanged(int? month) {
    setState(() {
      _month = month;
      _monthError = null;

      // Gün sayısını kontrol et
      if (_day != null && month != null) {
        final daysInMonth = _getDaysInMonth(month);
        if (_day! > daysInMonth) {
          _day = null;
          _dayError = 'Bu ayda en fazla $daysInMonth gün vardır';
        }
      }
    });
  }

  /// Gün seçimi
  void _onDayChanged(int? day) {
    setState(() {
      _day = day;
      _dayError = null;
    });
  }

  /// Ayın gün sayısını hesapla
  int _getDaysInMonth(int month) {
    const daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }

  /// Sonraki adıma geç
  void _goToNext() {
    if (!_isLocationConfirmed || _month == null || _day == null) return;

    final result = LocationDateResult(
      lat: _confirmedLatLng!.latitude,
      lon: _confirmedLatLng!.longitude,
      month: _month!,
      day: _day!,
      placeName: _confirmedPlaceName,
    );

    Navigator.pop(context, result);
  }

  /// Snackbar göster
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'MarineGuard',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Ayarlar sayfasına git
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Arama çubuğu
            _buildSearchBar(),

            // Harita (scroll içinde sabit yükseklik veriyoruz)
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _cameraLatLng,
                      zoom: 12,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onCameraIdle: _onCameraIdle,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Merkez pin
                  Center(
                    child: AnimatedBuilder(
                      animation: _pinAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pinAnimation.value * 0.1),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0288D1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // FAB'ler
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          onPressed: _isLoadingGeolocate
                              ? null
                              : _goToCurrentLocation,
                          backgroundColor: Colors.white,
                          child: _isLoadingGeolocate
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF0288D1),
                                ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true,
                          onPressed: _confirmedLatLng != null
                              ? _recenterToConfirmed
                              : null,
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.center_focus_strong,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Alt sheet
            _buildBottomSheet(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Arama çubuğu widget'ı
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TypeAheadField<PlaceSuggestion>(
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.roboto(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search place or coordinates…',
              hintStyle: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        controller.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0288D1),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          );
        },
        suggestionsCallback: _getSuggestions,
        itemBuilder: (context, suggestion) {
          return ListTile(
            leading: const Icon(Icons.location_on, color: Color(0xFF0288D1)),
            title: Text(
              suggestion.mainText ?? suggestion.description,
              style: GoogleFonts.roboto(fontSize: 16),
            ),
            subtitle: suggestion.secondaryText != null
                ? Text(
                    suggestion.secondaryText!,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
          );
        },
        onSelected: _onSuggestionSelected,
        hideOnEmpty: true,
        hideOnError: true,
        loadingBuilder: (context) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  /// Alt sheet widget'ı
  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve koordinatlar
                Text(
                  _confirmedPlaceName,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildCoordinateChip(
                        'Latitude: ${_cameraLatLng.latitude.toStringAsFixed(6)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCoordinateChip(
                        'Longitude: ${_cameraLatLng.longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Manuel koordinat girişi
                if (_showManualCoordinates) ...[
                  _buildManualCoordinatesInput(),
                  const SizedBox(height: 16),
                ],

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isReverseGeocoding
                            ? null
                            : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isReverseGeocoding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Use this location',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _toggleManualCoordinates,
                      child: Text(
                        'Refine on map',
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                if (!_showManualCoordinates) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _toggleManualCoordinates,
                      child: Text(
                        'Enter coordinates manually',
                        style: GoogleFonts.roboto(
                          color: Colors.grey[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Tarih seçimi
                _buildDateSelection(),

                const SizedBox(height: 24),

                // Next butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _isLocationConfirmed && _month != null && _day != null
                        ? _goToNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Koordinat chip widget'ı
  Widget _buildCoordinateChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700]),
      ),
    );
  }

  /// Manuel koordinat girişi widget'ı
  Widget _buildManualCoordinatesInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _latController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.roboto(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  errorText: _latError,
                  errorStyle: GoogleFonts.roboto(
                    color: const Color(0xFFD32F2F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lonController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.roboto(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  errorText: _lonError,
                  errorStyle: GoogleFonts.roboto(
                    color: const Color(0xFFD32F2F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveManualCoordinates,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update Location',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  /// Tarih seçimi widget'ı
  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _month,
                decoration: InputDecoration(
                  labelText: 'Month (1-12)',
                  errorText: _monthError,
                  errorStyle: GoogleFonts.roboto(
                    color: const Color(0xFFD32F2F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(value: month, child: Text('$month'));
                }),
                onChanged: _onMonthChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _day,
                decoration: InputDecoration(
                  labelText: 'Day (1-31)',
                  errorText: _dayError,
                  errorStyle: GoogleFonts.roboto(
                    color: const Color(0xFFD32F2F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _month != null
                    ? List.generate(_getDaysInMonth(_month!), (index) {
                        final day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text('$day'),
                        );
                      })
                    : [],
                onChanged: _onDayChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
