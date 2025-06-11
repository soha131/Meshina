import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cubit/time_model.dart';

class TravelService {
  final String _baseUrl = "http://10.0.2.2:8000";
  //final String _baseUrl = "http://192.168.100.3:8000";

  Future<TravelPredictionResponse> predictTravelTime(TravelData data) async {
    final isCarMode = data.mode.toLowerCase() == "car";
    final endpoint = isCarMode ? "/predict_car" : "/predict_duration";

    final url = Uri.parse("$_baseUrl$endpoint");

    // Prepare the body based on mode
    final body = isCarMode
        ? jsonEncode({
      'PU_lat': data.startLatitude,
      'PU_lng': data.startLongitude,
      'DO_lat': data.endLatitude,
      'DO_lng': data.endLongitude,
    })
        : jsonEncode(data.toJson());

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] != null) {
          throw Exception(responseData['error']);
        }

        return TravelPredictionResponse.fromJson(responseData);
      } else if (response.statusCode == 503) {
        final responseData = jsonDecode(response.body);
        print(responseData['detail'] ?? 'Service unavailable');

        throw Exception(responseData['detail'] ?? 'Service unavailable');

      } else {
        throw Exception('Failed to predict travel time');
      }
    } catch (e) {
      print("Error: $e");
      throw Exception('Error predicting travel time: $e');
    }
  }

}
