/// Konum ve tarih seçimi sonucu modeli
class LocationDateResult {
  final double lat;
  final double lon;
  final int month;
  final int day;
  final String placeName;

  const LocationDateResult({
    required this.lat,
    required this.lon,
    required this.month,
    required this.day,
    required this.placeName,
  });

  /// Koordinatları LatLng formatında döndür
  Map<String, double> get coordinates => {'lat': lat, 'lon': lon};

  /// Tarih bilgisini Map formatında döndür
  Map<String, int> get date => {'month': month, 'day': day};

  @override
  String toString() {
    return 'LocationDateResult(lat: $lat, lon: $lon, month: $month, day: $day, placeName: $placeName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationDateResult &&
        other.lat == lat &&
        other.lon == lon &&
        other.month == month &&
        other.day == day &&
        other.placeName == placeName;
  }

  @override
  int get hashCode {
    return lat.hashCode ^
        lon.hashCode ^
        month.hashCode ^
        day.hashCode ^
        placeName.hashCode;
  }

  /// JSON'dan model oluştur
  factory LocationDateResult.fromJson(Map<String, dynamic> json) {
    return LocationDateResult(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      month: json['month'] as int,
      day: json['day'] as int,
      placeName: json['placeName'] as String,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'month': month,
      'day': day,
      'placeName': placeName,
    };
  }
}
