/// Google Places API'den gelen yer önerisi modeli
class PlaceSuggestion {
  final String description;
  final String placeId;
  final String? mainText;
  final String? secondaryText;

  const PlaceSuggestion({
    required this.description,
    required this.placeId,
    this.mainText,
    this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;

    return PlaceSuggestion(
      description: json['description'] as String,
      placeId: json['place_id'] as String,
      mainText: structuredFormatting?['main_text'] as String?,
      secondaryText: structuredFormatting?['secondary_text'] as String?,
    );
  }

  @override
  String toString() {
    return 'PlaceSuggestion(description: $description, placeId: $placeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceSuggestion &&
        other.description == description &&
        other.placeId == placeId;
  }

  @override
  int get hashCode => description.hashCode ^ placeId.hashCode;
}
