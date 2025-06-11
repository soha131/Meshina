import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../carbon_service.dart';

class CarbonDashboardScreen extends StatefulWidget {
  const CarbonDashboardScreen({super.key});

  @override
  State<CarbonDashboardScreen> createState() => _CarbonDashboardScreenState();
}

class _CarbonDashboardScreenState extends State<CarbonDashboardScreen> {
  List<Map<String, dynamic>> carbonData = [];
  Map<String, double> usageCount = {};
  bool isLoading = true;
  String? error;
  int touchedIndex = -1;
  int _ecoPoints = 0;

  static Map<String, Color> transportColors = {
    "walking": Colors.green,
    "driving": Colors.purple,
    "transit": Colors.blue,
    "bicycling": Colors.green.shade700,

  };

  @override
  void initState() {
    super.initState();
    _fetchCarbonData();
    _loadEcoPoints();
  }

  List<Color> _getBlendedGradientColors(int index) {
    final entries = usageCount.entries.toList();
    final String currentMode = entries[index].key;
    final String nextMode = entries[(index + 1) % entries.length].key;

    final Color currentColor = transportColors[currentMode] ?? Colors.grey;
    final Color nextColor = transportColors[nextMode] ?? Colors.grey;

    return [
      currentColor.withOpacity(1.0),
      nextColor.withOpacity(1.0),
    ];
  }

  void _loadEcoPoints() async {
    final points = await CarbonService().getEcoPointsForUser();
    setState(() {
      _ecoPoints = points;
    });
  }

  Future<void> _fetchCarbonData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = "Login first please.";
          isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data()?['carbonContribution'] != null) {
        final List<dynamic> rawList = doc.data()?['carbonContribution'];
        final List<Map<String, dynamic>> formattedList = rawList.cast<Map<String, dynamic>>();


        setState(() {
          carbonData = formattedList;
          usageCount.clear();
          for (var entry in formattedList) {
            String mode = entry['transportMode'];
            usageCount[mode] = (usageCount[mode] ?? 0) + 1;
          }
          isLoading = false;
        });
      } else {
        setState(() {
          error = "No data .";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error while fetching data $e';
        isLoading = false;
      });
    }
  }

  Color _getChartColor(String mode) {
    return transportColors[mode] ?? Colors.grey;
  }

  IconData _getTransportIcon(String mode) {
    switch (mode) {
      case 'walking':
        return Icons.directions_walk;
      case 'bicycling':
        return Icons.directions_bike;
      case 'driving':
        return Icons.directions_car;
      case 'transit':
        return Icons.directions_bus;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildDetailsFromUsage(MapEntry<String, double> entry) {
    final String mode = entry.key;
    final double totalEmission = carbonData
        .map((e) => e['emission'] as num)
        .fold(0.0, (a, b) => a + b);
    final double emission = carbonData
        .where((e) => e['transportMode'] == mode)
        .map((e) => e['emission'] as num)
        .fold(0.0, (a, b) => a + b)
        .toDouble();
    final double emissionPercentage = (emission / totalEmission) * 100;

    final double points = carbonData
        .where((e) => e['transportMode'] == mode)
        .map((e) => e['ecoPoints'] as num)
        .fold(0.0, (a, b) => a + b)
        .toDouble();

    String emissionLevel;
    if (emission > 10) {
      emissionLevel = "High";
    } else if (emission > 5) {
      emissionLevel = "Medium";
    } else {
      emissionLevel = "Low";
    }

    return Column(
      children: [
        Text("CO₂ Emitted:${emission.toStringAsFixed(2)} KM", style: TextStyle(fontSize: 16)),
        Text("% of Total Emission:${emissionPercentage.toStringAsFixed(2)}%", style: TextStyle(fontSize: 16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Emission Level:"),
            CircleAvatar(radius: 6, backgroundColor: _getChartColor(mode)),
            SizedBox(width: 6),
            Text(emissionLevel, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Text("Points:$points", style: TextStyle(fontSize: 16)),
      ],
    );
  }
  Widget _buildEmptyDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "NO DATA",
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("back"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.close, size: 28, color: Color(0xFFACA3CF)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:  isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : carbonData.isEmpty || usageCount.isEmpty
          ? _buildEmptyDataWidget()
          :
    Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Carbon Wheel", style: TextStyle(fontSize: 20,  fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,)),
            const SizedBox(height: 20),
            const Text("You've Earned", style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/riyal.png", width: 30),
                const SizedBox(width: 10),
                Text(
                  " $_ecoPoints",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                      });
                    },
                  ),
                  sections: List.generate(usageCount.length, (index) {
                    final entry = usageCount.entries.elementAt(index);
                    final String mode = entry.key;
                    final double count = entry.value;

                    return PieChartSectionData(
                      gradient: LinearGradient(
                        colors: _getBlendedGradientColors(index),
                      ),
                      value: count,
                      showTitle: false,
                      radius: touchedIndex == index ? 70 : 60,
                      badgeWidget: Icon(_getTransportIcon(mode), color: Colors.white, size: 28),
                      badgePositionPercentageOffset: .50,
                    );
                  }),
                ),
              ),
            ),
            if (touchedIndex != -1) ...[
              const SizedBox(height: 20),
              _buildDetailsFromUsage(usageCount.entries.elementAt(touchedIndex)),
            ]
          ],
        ),
      ),
    );
  }
}
