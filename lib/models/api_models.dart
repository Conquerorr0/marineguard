class LocationInfo {
  final double lat;
  final double lon;
  const LocationInfo({required this.lat, required this.lon});

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};
  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
  );
}

class DateInfo {
  final int month;
  final int day;
  const DateInfo({required this.month, required this.day});

  Map<String, dynamic> toJson() => {'month': month, 'day': day};
  factory DateInfo.fromJson(Map<String, dynamic> json) =>
      DateInfo(month: json['month'] as int, day: json['day'] as int);
}

typedef ProbabilityMap = Map<String, double>;

class Metadata {
  final int totalEvents;
  final bool syntheticData;
  final List<String> customThresholds;
  const Metadata({
    required this.totalEvents,
    required this.syntheticData,
    required this.customThresholds,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
    totalEvents: (json['total_events'] as num).toInt(),
    syntheticData: (json['synthetic_data'] as bool? ?? false),
    customThresholds: ((json['custom_thresholds'] as List?) ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

class CalculateRequest {
  final LocationInfo location;
  final DateInfo date;
  final List<String> events;
  final Map<String, double>? thresholds;
  final bool? useSynthetic;

  const CalculateRequest({
    required this.location,
    required this.date,
    required this.events,
    this.thresholds,
    this.useSynthetic,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'lat': location.lat,
      'lon': location.lon,
      'month': date.month,
      'day': date.day,
      'events': events,
    };
    if (thresholds != null && thresholds!.isNotEmpty) {
      body['thresholds'] = thresholds;
    }
    if (useSynthetic != null) body['use_synthetic'] = useSynthetic;
    return body;
  }
}

class CalculateResponse {
  final bool success;
  final LocationInfo location;
  final DateInfo date;
  final ProbabilityMap probabilities;
  final Metadata metadata;

  const CalculateResponse({
    required this.success,
    required this.location,
    required this.date,
    required this.probabilities,
    required this.metadata,
  });

  factory CalculateResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>);
    final probs = <String, double>{};
    final p = (data['probabilities'] as Map?) ?? {};
    p.forEach((k, v) {
      if (v is num) probs[k.toString()] = v.toDouble();
    });
    return CalculateResponse(
      success: json['success'] as bool? ?? false,
      location: LocationInfo.fromJson(data['location'] as Map<String, dynamic>),
      date: DateInfo.fromJson(data['date'] as Map<String, dynamic>),
      probabilities: probs,
      metadata: Metadata.fromJson(data['metadata'] as Map<String, dynamic>),
    );
  }
}
