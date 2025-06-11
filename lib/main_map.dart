import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'arrived.dart';
import 'carbon_service.dart';
import 'cubit/route_option.dart';
import 'cubit/time_cubit.dart';
import 'cubit/time_model.dart';
import 'cubit/time_state.dart';
import 'features_screen/dashboard.dart';
import 'features_screen/points_currency.dart';
import 'features_screen/savedlist.dart';
import 'helper.dart';
import 'features_screen/live_location.dart';
import 'optimal_route.dart';
import 'widget/route_prediction_sheet.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum PanelContentType { defaultPanel, transportOptions }

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  final PanelController _panelController = PanelController();
  late PanelContentType _currentPanel = PanelContentType.defaultPanel;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final mapHelper = MapHelpers();
  String? _selectedTransport;

  int _ecoPoints = 0;
  double _lastEmission = 0.0;
  int _lastPointsEarned = 0;
  Color _emissionColor = Colors.green;
  final LatLng _center = const LatLng(24.7136, 46.6753); // Riyadh
  LatLng? selectedLocation;
  String _locationName = "Select Location";
  Set<Polyline> _polylines = {};
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _showTransportFields = false;

  final Map<String, double> _transportDistances = {};
  final Map<String, String> _transportTimes = {};
  late String userId;
  final Set<Marker> _markers = {};
  String? _displayedDistanceText;

  static const Map<String, String> transportModeMap = {
    "CAR": "driving",
    "WALK": "walking",
    "Bus": "transit",
    "Bicycle": "bicycling",
  };
  bool showAlternativeRoutes = false;
  List<RouteOption> alternativeRoutes = [];

  @override
  void initState() {
    super.initState();
    mapHelper.requestLocationPermission();
    _loadEcoPoints();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _startListening();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _animateMovingMarker(
    BuildContext context,
    List<LatLng> route,
    List<String> directions,
  ) async {
    for (int i = 0; i < route.length; i++) {
      LatLng newPosition = route[i];

      final moving = Marker(
        markerId: MarkerId("moving"),
        position: newPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: "جاري التحرك..."),
      );

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == "moving");
        _markers.add(moving);
      });

      if (i == 0 || i == route.length ~/ 2 || i == route.length - 1) {
        if (i < directions.length) {
          _speakDirections(directions[i]);
        }
      }
      await Future.delayed(Duration(milliseconds: 600));
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArrivedScreen(transportMode: _selectedTransport!),
      ),
    );
  }

  Future<void> _speakDirections(String direction) async {
    await _sendToGemini(direction);
  }

  Future<void> _getRouteFromOpenRouteService(LatLng from, LatLng to) async {
    final apiKey = "5b3ce3597851110001cf6248a87895fb63614261ab472dd7dcc3326f";
    final url = Uri.parse(
      "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${from.longitude},${from.latitude}&end=${to.longitude},${to.latitude}",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["features"] != null && data["features"].isNotEmpty) {
        final geometry = data["features"][0]["geometry"]["coordinates"];
        List<LatLng> polylineCoordinates = [];
        List<String> directions = [];

        for (var step
            in data["features"][0]["properties"]["segments"][0]["steps"]) {
          directions.add(step["instruction"]);
        }

        for (var point in geometry) {
          polylineCoordinates.add(LatLng(point[1], point[0]));
        }

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: PolylineId("route"),
              color: Color(0xFF8063cb),
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });

        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId("start"),
            position: from,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(title: "نقطة البداية"),
          ),
        );
        _markers.add(
          Marker(
            markerId: MarkerId("end"),
            position: to,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(title: "نقطة النهاية"),
          ),
        );
        setState(() {});

        if (polylineCoordinates.isNotEmpty) {
          LatLngBounds bounds = mapHelper.getLatLngBounds(polylineCoordinates);
          mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }

        await _animateMovingMarker(context, polylineCoordinates, directions);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No route found")));
      }
    } else {
      if (kDebugMode) {
        print("Failed to fetch data: ${response.statusCode}");
      }
    }
  }

  void _loadEcoPoints() async {
    final points = await CarbonService().getEcoPointsForUser();
    setState(() {
      _ecoPoints = points;
    });
  }

  Future<Map<String, dynamic>> calculateAndStoreEcoPoints({
    required String transportMode,
    required double distanceKm,
  }) async {
    if (distanceKm <= 0) {
      return {'emission': 0.0, 'earnedPoints': 0, 'emissionColor': Colors.grey};
    }

    final emissionData = mapHelper.calculateEmission(transportMode, distanceKm);
    final double emission = emissionData['emission'];
    final int earnedPoints = emissionData['points'];
    final Color emissionColor = emissionData['color'];

    setState(() {
      _lastEmission = emission;
      _lastPointsEarned = earnedPoints;
      _emissionColor = emissionColor;
    });

    return {
      'emission': emission,
      'earnedPoints': earnedPoints,
      'emissionColor': emissionColor,
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _searchLocation(String place) async {
    try {
      List<Location> locations = await locationFromAddress(place);
      if (locations.isNotEmpty) {
        _updateMapLocation(
          LatLng(locations.first.latitude, locations.first.longitude),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error finding location")));
    }
  }

  void _updateMapLocation(LatLng newLocation) {
    setState(() {
      selectedLocation = newLocation;
    });

    mapController.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 15));

    if (selectedLocation != null) {
      _updateLocationName(selectedLocation!);
    }
  }

  Future<void> _updateLocationName(LatLng position) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String address = data["display_name"] ?? "Unknown Location";

        setState(() {
          _locationName = address;
          searchController.text = _locationName;
        });
      } else {
        /* messenger.showSnackBar(
          SnackBar(content: Text("Error fetching address: ${response.statusCode}")),
        );*/
      }
    } catch (e) {
      /* messenger.showSnackBar(
        SnackBar(content: Text("Error getting location: ${e.toString()}")),
      );*/
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      await _speech.stop();
      setState(() => _isListening = true);

      _speech.listen(
        localeId: 'ar_EG',
        onResult: (result) {
          if (result.finalResult) {
            _sendToGemini(result.recognizedWords);
          }
        },
      );
    }
  }

  Future<void> _sendToGemini(String message) async {
    final apiKey = 'AIzaSyCVHz2qirJoc59SUUqZX4BS6tQN8yRc43k';
    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-001:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "رد عليّ دائمًا باللغة العربية فقط. من فضلك عبّر عن التوجيه التالية بصيغة أوامر مختصرة وواضحة كأنك نظام GPS: $message",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseText =
            data['candidates'][0]['content']['parts'][0]['text'];
        await _speak(responseText, shouldListen: false); // مهم جدا
      } else {
        _speak('Sorry, there was an error from Gemini: ${response.statusCode}');
      }
    } catch (e) {
      _speak('An error occurred: $e');
    }
  }

  Future<void> _speak(String text, {bool shouldListen = false}) async {
    await _flutterTts.setLanguage("ar-EG");
    await _flutterTts.setSpeechRate(0.5);

    await _flutterTts.speak(text);
    await _flutterTts.awaitSpeakCompletion(true);

    if (shouldListen) {
      _startListening();
    }
  }

  Future<void> _getUserLocationAndSetText(
    TextEditingController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    var status = await Permission.location.request();

    if (status.isPermanentlyDenied) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Enable location manually in settings.")),
      );
      openAppSettings();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      _updateMapLocation(LatLng(position.latitude, position.longitude));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address =
            "${place.street}, ${place.subLocality}, ${place.locality}";
        controller.text = address;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error getting location: ${e.toString()}")),
      );
    }
  }

  Future<void> handleTransportOptionTap() async {
    if (showAlternativeRoutes) {
      setState(() {
        showAlternativeRoutes = false;
      });
      return;
    }

    final fromLocation = await mapHelper.getLocationFromAddress(
      fromController.text,
    );
    final toLocation = await mapHelper.getLocationFromAddress(
      toController.text,
    );

    if (fromLocation != null && toLocation != null) {
      try {
        final routesData = await mapHelper.getAlternativeRoutes(
          fromLocation,
          toLocation,
        );

        final List<RouteOption> routes = [];
        final colors = [Color(0xff618728), Colors.grey, Color(0xFF8063cb)];
        final names = ['route a', 'route b', 'route c'];

        for (int i = 0; i < routesData.length; i++) {
          final route = routesData[i];
          final polyline = mapHelper.decodePolyline(route['geometry']);

          routes.add(
            RouteOption(
              name: names[i],
              color: colors[i],
              polylinePoints: polyline,
              distance: route['distance'],
              duration: route['duration'],
              emission: route['emission'],
            ),
          );
        }

        setState(() {
          alternativeRoutes = routes;
          showAlternativeRoutes = true;
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل المسارات البديلة.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("من فضلك تأكد من أن العناوين صحيحة.")),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    mapController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              polylines: _polylines,
              markers: _markers,
            ),
            Positioned(
              right: 10,
              top: 80,
              child: Image.asset(
                "assets/icons/alart.png",
                width: 50,
                height: 50,
              ),
            ),
            if (_showTransportFields) ...[
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.1)),
                ),
              ),
              Positioned(
                top: 150,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    _buildInputField("From", fromController),
                    const SizedBox(height: 20),
                    _buildInputField("To", toController),
                  ],
                ),
              ),
            ],

            /*  if (_displayedDistanceText != null)
              Positioned(
                top: 10,
                left: 110,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Distance:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF8063cb),
                        ),
                      ),
                      Text(
                        "${_displayedDistanceText!}\\KM",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),*/
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Row(
                  children: [
                    Text(
                      'ecoPoints: $_ecoPoints🪙',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            /// Sliding Panel
            SlidingUpPanel(
              controller: _panelController,
              minHeight: 80,
              maxHeight: 380,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15.0)],
              panelBuilder: (sc) => _buildPanel(sc),
              collapsed: _buildCollapsedBar(),
            ),
          ],
        ),
      ),
    );
  }

  /// Search Bar Widget (reused)
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(0.8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDCC2FF), Color(0xFF9386FC)],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.bot),
              onPressed: () async {
                await _flutterTts.stop();
                _startListening();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onSubmitted: _searchLocation,
              decoration: const InputDecoration(
                hintText: "Search location...",
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFFACA3CF)),

                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Color(0xFF9087CC),
              size: 30,
            ),
            onPressed: _startListening,
          ),
        ],
      ),
    );
  }

  /// Collapsed Bar (includes search bar)
  Widget _buildCollapsedBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: _buildSearchBar(),
    );
  }

  /// Full Panel when expanded (includes search bar at top)
  Widget _buildPanel(ScrollController sc) {
    switch (_currentPanel) {
      case PanelContentType.transportOptions:
        return _buildTransportPanel(sc);
      case PanelContentType.defaultPanel:
        return _buildDefaultPanel(sc);
    }
  }

  Widget _buildDefaultPanel(ScrollController sc) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? "Guest";
    final String? photoURL = user?.photoURL;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE0E0F1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            gradient: LinearGradient(
              colors: [Color(0xFFEEE8F8), Color(0xFFE0D3F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.only(top: 80),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 0),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: 0,
                      child: Image.asset(
                        "assets/icons/tree.png",
                        width: 70,
                        height: 320,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Profile section
                    Row(
                      children: [
                        if (photoURL != null)
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(photoURL),
                          )
                        else
                          const CircleAvatar(
                            radius: 25,
                            child: Icon(Icons.person, size: 25),
                          ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Profile",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF2F1532),
                              ),
                            ),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFFACA3CF),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "Points: ",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFFACA3CF),
                                  ),
                                ),
                                Text(
                                  " $_ecoPoints",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xff98BA50),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 5,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CarbonDashboardScreen(),
                              ),
                            );
                          },
                          child: _featureIcon(
                            AssetImage("assets/icons/carbon.png"),
                            "Carbon footprint",
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PointsCurrencyScreen(),
                              ),
                            );
                          },
                          child: _featureIcon(
                            AssetImage("assets/icons/saudi-riyal.png"),
                            "Points",
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentPanel = PanelContentType.transportOptions;
                              _showTransportFields = true;
                            });
                          },
                          child: _featureIcon(
                            AssetImage("assets/icons/mode.png"),
                            "Transport Mode",
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveLocationScreen(),
                              ),
                            );
                          },
                          child: _featureIcon(
                            AssetImage("assets/icons/location.png"),
                            "Live Location",
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SavedListScreen(),
                              ),
                            );
                          },
                          child: _featureIcon(
                            AssetImage("assets/icons/savelist.png"),
                            "Saved List",
                          ),
                        ),
                        _featureIcon("", ""),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// Search bar fixed at top of panel
        Positioned(top: 20, left: 0, right: 0, child: _buildSearchBar()),
      ],
    );
  }

  Widget _buildTransportPanel(ScrollController sc) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0F1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFFB58FE7), Color(0xFFE0D3F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Stack(
              children: [
                Positioned(
                  left: -10,
                  top: 15,
                  child: Image.asset(
                    "assets/icons/Group.png",
                    width: 80,
                    height: 400,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 80,
                  child: Image.asset(
                    "assets/icons/tree.png",
                    width: 70,
                    height: 320,
                  ),
                ),

              ],
            ),
          ),
          SingleChildScrollView(
            controller: sc,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showAlternativeRoutes)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, left: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          alternativeRoutes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final route = entry.value;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2.0,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: route.color,
                                  shape: StadiumBorder(),
                                ),
                                onPressed: () async {
                                  final from = await mapHelper
                                      .getLocationFromAddress(
                                        fromController.text,
                                      );
                                  final to = await mapHelper
                                      .getLocationFromAddress(
                                        toController.text,
                                      );

                                  if (from != null && to != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => RouteComparisonScreen(
                                              from: from,
                                              to: to,
                                              initialRouteIndex: index,
                                            ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("تحقق من العناوين."),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  route.name,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                const SizedBox(height: 20),
                BlocListener<TravelCubit, TravelState>(
                  listener: (context, state) {
                    if (state is TravelSuccess) {
                      setState(() {
                        _transportTimes[_selectedTransport!] =
                            "${state.predictedTime} دقيقة";
                        _transportDistances[_selectedTransport!] =
                            state.calculatedDistance;
                      });
                    } else if (state is TravelError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل التوقع: ${state.errorMessage}'),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 60,
                      top: 10,
                      right: 100,
                      bottom: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: [
                            _transportOption(
                              "CAR",
                              _transportTimes["CAR"] ?? "",
                              LucideIcons.car,
                              highlight: _selectedTransport == "CAR",
                              onTap: () async {
                                setState(() {
                                  _selectedTransport = "CAR";
                                });
                                final fromLocation = await mapHelper
                                    .getLocationFromAddress(
                                      fromController.text,
                                    );
                                final toLocation = await mapHelper
                                    .getLocationFromAddress(toController.text);

                                if (fromLocation != null &&
                                    toLocation != null) {
                                  final travelData = TravelData(
                                    startLatitude: fromLocation.latitude,
                                    startLongitude: fromLocation.longitude,
                                    endLatitude: toLocation.latitude,
                                    endLongitude: toLocation.longitude,
                                    mode: "Car",
                                  );

                                  context.read<TravelCubit>().predictTravelTime(
                                    travelData,
                                  );
                                }
                              },
                            ),
                            _transportOption(
                              "Bus",
                              _transportTimes["Bus"] ?? "",
                              Icons.directions_bus,
                              highlight: _selectedTransport == "Bus",
                              onTap: () async {
                                setState(() {
                                  _selectedTransport = "Bus";
                                });
                                final fromLocation = await mapHelper
                                    .getLocationFromAddress(
                                      fromController.text,
                                    );
                                final toLocation = await mapHelper
                                    .getLocationFromAddress(toController.text);

                                if (fromLocation != null &&
                                    toLocation != null) {
                                  final travelData = TravelData(
                                    startLatitude: fromLocation.latitude,
                                    startLongitude: fromLocation.longitude,
                                    endLatitude: toLocation.latitude,
                                    endLongitude: toLocation.longitude,
                                    mode: "Bus",
                                  );

                                  context.read<TravelCubit>().predictTravelTime(
                                    travelData,
                                  );
                                }
                                _loadEcoPoints();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: [
                            _transportOption(
                              "WALK",
                              _transportTimes["WALK"] ?? "",
                              Icons.directions_walk,
                              highlight: _selectedTransport == "WALK",
                              onTap: () async {
                                setState(() {
                                  _selectedTransport = "WALK";
                                });
                                final fromLocation = await mapHelper
                                    .getLocationFromAddress(
                                      fromController.text,
                                    );
                                final toLocation = await mapHelper
                                    .getLocationFromAddress(toController.text);

                                if (fromLocation != null &&
                                    toLocation != null) {
                                  final travelData = TravelData(
                                    startLatitude: fromLocation.latitude,
                                    startLongitude: fromLocation.longitude,
                                    endLatitude: toLocation.latitude,
                                    endLongitude: toLocation.longitude,
                                    mode: "Walk",
                                  );
                                  context.read<TravelCubit>().predictTravelTime(
                                    travelData,
                                  );
                                }

                                _loadEcoPoints();
                              },
                            ),

                            _transportOption(
                              "Bicycle",
                              _transportTimes["Bicycle"] ?? "",
                              LucideIcons.bike,
                              highlight: _selectedTransport == "Bicycle",
                              onTap: () async {
                                setState(() {
                                  _selectedTransport = "Bicycle";
                                });
                                final fromLocation = await mapHelper
                                    .getLocationFromAddress(
                                      fromController.text,
                                    );
                                final toLocation = await mapHelper
                                    .getLocationFromAddress(toController.text);

                                if (fromLocation != null &&
                                    toLocation != null) {
                                  final travelData = TravelData(
                                    startLatitude: fromLocation.latitude,
                                    startLongitude: fromLocation.longitude,
                                    endLatitude: toLocation.latitude,
                                    endLongitude: toLocation.longitude,
                                    mode: "Bicycle",
                                  );
                                  context.read<TravelCubit>().predictTravelTime(
                                    travelData,
                                  );
                                }

                                _loadEcoPoints();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xffD9D9D9),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPanel =
                                        PanelContentType.defaultPanel;
                                    _selectedTransport = null;
                                  });
                                  mapController.animateCamera(
                                    CameraUpdate.newLatLngZoom(_center, 14),
                                  );
                                },

                                icon: Icon(
                                  LucideIcons.undo2,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 60),
                            GestureDetector(
                              onTap: () async {
                                String to = toController.text.trim();
                                if (to.isNotEmpty &&
                                    _selectedTransport != null) {
                                  final state =
                                      context.read<TravelCubit>().state;
                                  if (state is TravelSuccess) {
                                    final predictedTime = state.predictedTime;
                                    final calculatedDistance =
                                        state.calculatedDistance;
                                    final weather = state.weather;
                                    final hourOfDay = state.hourOfDay;
                                    int totalMinutes = predictedTime.round();

                                    RoutePredictionSheet.show(
                                      context,
                                      _selectedTransport!,
                                      to,
                                      totalMinutes,
                                      weather,
                                      calculatedDistance,
                                        hourOfDay
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("لم يتم تحديد وقت بعد"),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "من فضلك اختر وسيلة نقل ووجهة",
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Image.asset(
                                'assets/icons/bot.png',
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 5,
            top: showAlternativeRoutes ? 150 : 80,
            child: ClipPath(
              clipper: HexagonClipper(),
              child: Material(
                color: Color(0xff618728),
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      _showTransportFields = false;
                    });
                    if (_selectedTransport != null &&
                        fromController.text.isNotEmpty &&
                        toController.text.isNotEmpty) {
                      String transportMode =
                          transportModeMap[_selectedTransport!] ??
                              "driving";
                      double distanceKm =
                          _transportDistances[_selectedTransport!] ?? 0.0;
                      setState(() {
                        _displayedDistanceText =
                        " ${distanceKm.toStringAsFixed(2)}";
                      });

                      if (distanceKm == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "تعذر حساب المسافة. حاول مرة أخرى.",
                            ),
                          ),
                        );
                        return;
                      }
                      await calculateAndStoreEcoPoints(
                        transportMode: transportMode,
                        distanceKm: distanceKm,
                      );
                      String feedbackMessage;
                      if (transportMode == "walking" ||
                          transportMode == "bicycling") {
                        feedbackMessage = "🚶 كسبت 15 نقطة خضراء! استمر!";
                      } else if (transportMode == "bus" ||
                          transportMode == "transit" ||
                          transportMode == "metro") {
                        feedbackMessage =
                        "🚌 كسبت 5 نقاط للمساهمة البيئية!";
                      } else if (transportMode == "driving") {
                        feedbackMessage =
                        "🚗 خسرت 10 نقاط! جرّب خيار أوفر!";
                      } else {
                        feedbackMessage = "تم تحديث النقاط والانبعاثات.";
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(feedbackMessage),
                          duration: Duration(seconds: 3),
                          backgroundColor: Colors.black87,
                        ),
                      );
                      await mapHelper.saveTripToFirestore(
                        context: context,
                        from: fromController.text,
                        to: toController.text,
                        transportMode: transportMode,
                        distanceKm: distanceKm,
                        feedbackMessage: feedbackMessage,
                      );

                      await mapHelper.updateUserCarbonContribution(
                        userId,
                        transportMode,
                        distanceKm,
                      );
                      final fromLocation = await mapHelper
                          .getLocationFromAddress(fromController.text);
                      final toLocation = await mapHelper
                          .getLocationFromAddress(toController.text);

                      if (fromLocation != null && toLocation != null) {
                        _getRouteFromOpenRouteService(
                          fromLocation,
                          toLocation,
                        );
                        setState(() {
                          _panelController.open();
                        });
                        _loadEcoPoints();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Invalid locations")),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 110,
                    height: 90,
                    alignment: Alignment.center,
                    child: Text(
                      "YALLA?",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: TextFormField(
        controller: controller,
        onFieldSubmitted: (_) {
          if (controller.text.trim().isNotEmpty) {
            handleTransportOptionTap();
          }
        },
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),

          filled: true,
          fillColor: Color(0xff8063cb),

          suffixIcon:
              (label == "From")
                  ? IconButton(
                    icon: Icon(Icons.my_location,color: Colors.white,),
                    onPressed: () async {
                      await _getUserLocationAndSetText(controller);
                    },
                  )
                  : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _transportOption(
    String modeName,
    String time,
    IconData icon, {
    bool highlight = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? Colors.white : Color(0xff8063cb),
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              highlight
                  ? [
                    BoxShadow(
                      color: Color(0xff98BA50),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: highlight ? Colors.purple : Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              modeName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time.isNotEmpty ? time : "",
              style: TextStyle(
                fontSize: 12,
                color: highlight ? Color(0xff518b38) : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Icon tile widget
  Widget _featureIcon(dynamic icon, String? label) {
    Widget? iconWidget;

    if (icon is ImageProvider) {
      iconWidget = Image(
        image: icon,
        width: 40,
        height: 30,
        fit: BoxFit.fitHeight,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconWidget != null)
          Container(
            decoration: BoxDecoration(
              color: Color(0xffC5D97C),
              shape: BoxShape.rectangle,
              gradient: LinearGradient(
                colors: [Color(0xffc7d1a6), Color(0xffC5D97C)],
                begin: Alignment.topLeft,
                tileMode: TileMode.repeated,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),

            padding: const EdgeInsets.all(15),
            child: iconWidget,
          ),
        if (iconWidget != null) const SizedBox(height: 5),
        if (label != null)
          Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF696581))),
      ],
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double width = size.width;
    final double height = size.height;
    final double side = width / 2;

    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.75, 0);
    path.lineTo(width, height * 0.5);
    path.lineTo(width * 0.75, height);
    path.lineTo(width * 0.25, height);
    path.lineTo(0, height * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
