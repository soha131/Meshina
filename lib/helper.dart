import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class MapHelpers {
  static const Map<String, String> transportModeReverseMap = {
    "driving": "CAR",
    "walking": "WALK",
    "transit": "Bus",
    "bicycling": "Bicycle",
  };
  Future<LatLng?> getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Error converting address to location: $e");
    }
    return null;
  }
  Map<String, dynamic> calculateEmission(String transportMode, double distanceKm) {
    transportMode = transportMode.toLowerCase();

    final emissionRates = {
      "driving": 0.192,
      "walking": 0.0,
      "bicycling": 0.0,
      "transit": 0.105,
      "metro": 0.041,
      "bus": 0.105,
    };

    final emissionColors = {
      "driving": Colors.purple,
      "walking": Colors.green,
      "bicycling": Colors.green,
      "transit": Colors.blue,
      "metro": Colors.blue,
      "bus": Colors.blue,
    };

    double emissionPerKm = emissionRates[transportMode] ?? emissionRates["driving"]!;
    Color color = emissionColors[transportMode] ?? emissionColors["driving"]!;
    double emission = distanceKm * emissionPerKm;

    int earnedPoints;
    switch (transportMode) {
      case "walking":
      case "bicycling":
        earnedPoints = 15;
        break;
      case "bus":
      case "transit":
      case "metro":
        earnedPoints = 5;
        break;
      case "driving":
        earnedPoints = -10;
        break;
      default:
        earnedPoints = 0;
        break;
    }

    return {'emission': emission, 'points': earnedPoints, 'color': color};
  }

  LatLngBounds getLatLngBounds(List<LatLng> points) {
    double? minLat, minLng, maxLat, maxLng;

    for (var point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }


  Future<void> updateUserCarbonContribution(
      String userId,
      String transportMode,
      double distanceKm,
      ) async {
    Map<String, dynamic> emissionData = calculateEmission(
      transportMode,
      distanceKm,
    );

    double emission = emissionData['emission'];
    int ecoPoints = emissionData['points'];
    String color = emissionData['color'].toString();

    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);

      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      if (!snapshot.exists) {
        transaction.set(userRef, {
          'carbonContribution': [],
          'totalEcoPoints': 0,
        });
      }

      int currentPoints = data != null && data.containsKey('totalEcoPoints')
          ? data['totalEcoPoints'] as int
          : 0;

      List<dynamic> currentContributions = data != null && data.containsKey('carbonContribution')
          ? List.from(data['carbonContribution'])
          : [];

      currentContributions.add({
        'transportMode': transportMode,
        'emission': emission,
        'ecoPoints': ecoPoints,
        'color': color,
        'date': Timestamp.now(),
      });

      transaction.set(userRef, {
        'carbonContribution': currentContributions,
        'totalEcoPoints': currentPoints + ecoPoints,
      }, SetOptions(merge: true));
    });

    print('✅ تم تحديث البيانات بنجاح');
  }
  Future<void> saveTripToFirestore({
    required BuildContext context,
    required String from,
    required String to,
    required String transportMode,
    required double distanceKm,
    required String feedbackMessage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("لم يتم تسجيل الدخول!")));
      return;
    }
    final readableTransport =
        transportModeReverseMap[transportMode] ?? transportMode;

    Map<String, dynamic> tripData = {
      'from': from,
      'to': to,
      'transportMode': readableTransport,
      'distanceKm': distanceKm,
      'feedbackMessage': feedbackMessage,
      'timestamp': DateTime.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .add(tripData);
      debugPrint("تم حفظ الرحلة بنجاح ✅");
    } catch (e) {
      debugPrint("فشل في حفظ الرحلة: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الحفظ!")));
    }
  }

  Future<List<Map<String, dynamic>>> getAlternativeRoutes(LatLng from, LatLng to) async {
    final double distanceKm = calculateDistanceKm(from, to);
     const String _apiKey = "5b3ce3597851110001cf6248a87895fb63614261ab472dd7dcc3326f";
     const String _baseUrl = "https://api.openrouteservice.org/v2/directions/driving-car/geojson";

    final Map<String, dynamic> requestBody = {
      "coordinates": [
        [from.longitude, from.latitude],
        [to.longitude, to.latitude]
      ]
    };

    if (distanceKm <= 140) {
      requestBody["alternative_routes"] = {
        "target_count": 3,
        "share_factor": 0.6,
        "weight_factor": 1.6
      };
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Authorization": _apiKey,
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch routes: ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['features'] == null) {
      throw Exception('No routes found: ${response.body}');
    }

    final List<Map<String, dynamic>> routes = [];
    final features = data['features'] as List<dynamic>;

    for (var feature in features) {
      final props = feature['properties'];
      final segment = props['segments'][0];
      final distance = segment['distance'] / 1000;
      final duration = segment['duration'] / 60;

      final emission = distance * 0.192;

      routes.add({
        'geometry': feature['geometry'],
        'distance': distance,
        'duration': duration,
        'emission': emission,
      });
    }

    return routes;
  }
  double calculateDistanceKm(LatLng p1, LatLng p2) {
    const double R = 6371; // Radius of Earth in km
    double dLat = (p2.latitude - p1.latitude) * pi / 180;
    double dLon = (p2.longitude - p1.longitude) * pi / 180;
    double a = sin(dLat/2) * sin(dLat/2) +
        cos(p1.latitude * pi / 180) * cos(p2.latitude * pi / 180) *
            sin(dLon/2) * sin(dLon/2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }
  List<LatLng> decodePolyline(Map<String, dynamic> geometry) {
    final coords = geometry['coordinates'];
    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  void requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      print("تم الحصول على إذن الوصول إلى الموقع");
    } else if (status.isDenied) {
      print("تم رفض إذن الوصول إلى الموقع");
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}