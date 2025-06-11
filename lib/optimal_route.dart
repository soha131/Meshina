import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'helper.dart';

class RouteComparisonScreen extends StatefulWidget {
  final LatLng from;
  final LatLng to;
  final int? initialRouteIndex;
  const RouteComparisonScreen({super.key, required this.from, required this.to, this.initialRouteIndex});

  @override
  State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
  List<Map<String, dynamic>> routes = [];
  final Set<Polyline> _polylines = {};
  int? selectedRouteIndex;
  final mapHelper = MapHelpers();

  @override
  void initState() {
    super.initState();
    selectedRouteIndex = widget.initialRouteIndex;
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    routes = await mapHelper.getAlternativeRoutes(widget.from, widget.to);
    drawRoutes(routes);
  }

  void drawRoutes(List<Map<String, dynamic>> routes) {
    _polylines.clear();

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final polylineId = PolylineId("route_$i");

      final color = (selectedRouteIndex == i)
          ?Color(0xff518b38)
          : (i == 0 ? Color(0xFF8063cb) : Color(0xFFACA3CF));

      final coords = mapHelper.decodePolyline(route['geometry']);

      _polylines.add(Polyline(
        polylineId: polylineId,
        color: color,
        width: 5,
        points: coords,
      ));
    }

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final best = routes.isNotEmpty
        ? routes.reduce((a, b) => a['emission'] < b['emission'] ? a : b)
        : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          'Optimal Route',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF19142B),
          ),
        ),
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
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.from,
                zoom: 13,
              ),
              polylines: _polylines,
              myLocationEnabled: true,
            ),
          ),
          if (routes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: routes.length,
                itemBuilder: (context, i) {
                  final route = routes[i];
                  final saving = ((1 - best!['emission'] / route['emission']) * 100).toStringAsFixed(1);
                  return Card(
                    color: selectedRouteIndex == i ? Colors.green[100] : Color(
                        0xFFDEDBEA),
                    child: ListTile(
                      title:  Text("Route ${String.fromCharCode(65 + i)}",style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        //color: Color(0xFF8063cb),
                      ),),
                      subtitle: Column(
                        children: [
                          Row(
                            children: [
                              Row(
                                children: [
                                  Text(
                                      "Time: ",style:  TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:selectedRouteIndex == i ? Color(0xff177c39) :  Color(0xFF8063cb),
                                  ),
                                  ),
                                  Text(
                                      "${route['duration'].toStringAsFixed(0)} Min"
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [

                              Row(
                                children: [
                                  Text(
                                      "Distance:",style:  TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:selectedRouteIndex == i ? Color(0xff518b38) :  Color(0xFF8063cb),
                                  ),
                                  ),
                                  Text(
                                      " ${route['distance'].toStringAsFixed(2)} Km"
                                  ),
                                ],
                              ),

                            ],
                          ),
                          Row(
                            children: [

                              Text(
                                  "Emission:",style:  TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color:selectedRouteIndex == i ? Color(0xff518b38) :  Color(0xFF8063cb),
                              ),
                              ),
                              Text(
                                  "${route['emission'].toStringAsFixed(2)} Km CO2"
                              )
                            ],
                          ),
                              Center(
                                child: Text(
                                    route != best ? 'يوفر $saving% كربون أقل من الأفضل' : 'هذا هو المسار الأفضل 🌿'
                                ),
                              ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          selectedRouteIndex = i;
                          drawRoutes(routes);
                        });
                        Future.delayed(Duration(seconds: 2), () {
                          Navigator.pop(context, routes[i]);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
