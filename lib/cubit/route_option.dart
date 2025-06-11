import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteOption {
  final String name;
  final Color color;
  final List<LatLng> polylinePoints;
  final double distance;
  final double duration;
  final double emission;

  RouteOption({
    required this.name,
    required this.color,
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.emission,
  });
}
