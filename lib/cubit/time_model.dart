class TravelData {
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final String mode;

  TravelData({
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'transport_mode': mode,
    };
  }
}

class TravelPredictionResponse {
  final double predictedDurationMin;
  final double distanceKm;
  final String transportMode;
  final String weather;
  final int hourOfDay;

  TravelPredictionResponse({
    required this.predictedDurationMin,
    required this.distanceKm,
    required this.transportMode,
    required this.weather,
    required this.hourOfDay,
  });

  factory TravelPredictionResponse.fromJson(Map<String, dynamic> json) {
    final inputFeatures = json['input_features'] as Map<String, dynamic>?;

    if (json['predicted_duration_minutes'] == null || inputFeatures == null) {
      throw Exception("Missing required fields in response");
    }

    return TravelPredictionResponse(
      predictedDurationMin: (json['predicted_duration_minutes'] as num).toDouble(),
      distanceKm: (inputFeatures['distance_km'] as num?)?.toDouble() ?? 0.0,
      transportMode: 'Car',
      weather: inputFeatures['weather'] ?? 'Unknown',
      hourOfDay: (inputFeatures['hour_of_day'] as num?)?.toInt() ?? 0,
    );
  }


}
