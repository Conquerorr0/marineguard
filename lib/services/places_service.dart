import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marineguard/models/place_suggestion.dart';

/// Google Places API servisi
class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey;

  PlacesService({required this.apiKey});

  /// Place autocomplete önerilerini getir
  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$apiKey'
        '&types=geocode'
        '&language=tr'
        '&components=country:tr', // Türkiye'ye odaklan
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map((prediction) => PlaceSuggestion.fromJson(prediction))
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw PlacesServiceException(
            'Places API hatası: ${data['status']}',
            status: data['status'],
          );
        }
      } else {
        throw PlacesServiceException(
          'HTTP hatası: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PlacesServiceException) rethrow;
      throw PlacesServiceException('Ağ hatası: $e');
    }
  }

  /// Place ID'den koordinatları getir
  Future<Map<String, double>> getPlaceLatLng(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>;
          final location = geometry['location'] as Map<String, dynamic>;

          return {
            'lat': (location['lat'] as num).toDouble(),
            'lng': (location['lng'] as num).toDouble(),
          };
        } else {
          throw PlacesServiceException(
            'Place details API hatası: ${data['status']}',
            status: data['status'],
          );
        }
      } else {
        throw PlacesServiceException(
          'HTTP hatası: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is PlacesServiceException) rethrow;
      throw PlacesServiceException('Ağ hatası: $e');
    }
  }

  /// Koordinatlardan adres bilgisi getir (reverse geocoding)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$apiKey'
        '&language=tr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0] as Map<String, dynamic>;
          return result['formatted_address'] as String;
        } else {
          return 'Dropped Pin';
        }
      } else {
        return 'Dropped Pin';
      }
    } catch (e) {
      return 'Dropped Pin';
    }
  }
}

/// Places servisi hataları
class PlacesServiceException implements Exception {
  final String message;
  final String? status;
  final int? statusCode;

  PlacesServiceException(this.message, {this.status, this.statusCode});

  @override
  String toString() {
    if (status != null) {
      return 'PlacesServiceException [$status]: $message';
    } else if (statusCode != null) {
      return 'PlacesServiceException [$statusCode]: $message';
    }
    return 'PlacesServiceException: $message';
  }
}
