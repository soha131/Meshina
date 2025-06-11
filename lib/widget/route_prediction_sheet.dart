import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RoutePredictionSheet {
  static void show(BuildContext context, String transport, String destination, int durationMinutes, String weather, double distanceKm,int hourOfDay) {
    String traffic = _getRandomTraffic();
    String roadIssue = _getRandomRoadIssue();
    int estimatedTime = _calculateEstimatedTime(durationMinutes, traffic, roadIssue, transport);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor:Color(0xFFD7D6DA),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_handle, color: Colors.grey[600]),
                SizedBox(height: 10),
                Text(" Reporting System", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Color(0xFF8063cb))),
                Divider(thickness: 1.2),
                _buildInfoTile(Icons.location_on, "Destination", destination),
                _buildInfoTile(Icons.directions, "Transport Mode", transport),
                _buildInfoTile(LucideIcons.alignJustify, "Distance", "$distanceKm KM"),
                _buildInfoTile(Icons.timer, "EstimatedTime", "$estimatedTime  Min"),
                _buildInfoTile(Icons.traffic, "Traffic", traffic),
                _buildInfoTile(Icons.cloud, "Weather", weather),
                _buildInfoTile(Icons.warning_amber, "RoadIssue", roadIssue),
                _buildInfoTile(
                    Icons.access_time,
                    "hourOfDay",
                    "$hourOfDay"
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon,color:Color(0xFF8063cb) ),
      title: Text(title, style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xff365a44),
      ),),
      subtitle: Text(subtitle, style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),),
    );
  }

  static String _getRandomTraffic() {
    const trafficOptions = ["Light", "Moderate", "Heavy"];
    return trafficOptions[Random().nextInt(trafficOptions.length)];
  }

  static String _getRandomRoadIssue() {
    const issues = ["None", "Accident", "Construction", "Detour"];
    return issues[Random().nextInt(issues.length)];
  }

  static int _calculateEstimatedTime(int baseTime, String traffic, String issue, String transport) {
    if (transport.toLowerCase() == "car") {
      return baseTime;
    }

    if (traffic == "Moderate") {
      baseTime += 10;
    } else if (traffic == "Heavy") {
      baseTime += 20;
    }

    if (issue == "Accident") {
      baseTime += 15;
    } else if (issue == "Construction") {
      baseTime += 10;
    } else if (issue == "Detour") {
      baseTime += 12;
    }
    return baseTime;
  }

}
