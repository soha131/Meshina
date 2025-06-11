import 'package:flutter/material.dart';
import '../carbon_service.dart';

class PointsCurrencyScreen extends StatefulWidget {
  const PointsCurrencyScreen({super.key});

  @override
  State<PointsCurrencyScreen> createState() => _PointsCurrencyScreenState();
}

class _PointsCurrencyScreenState extends State<PointsCurrencyScreen> {
  int _ecoPoints = 0;
  double _riyals = 0;

  void _loadEcoPoints() async {
    final points = await CarbonService().getEcoPointsForUser();
    setState(() {
      _ecoPoints = points;
      _convertPointsToRiyals();
    });

  }

  void _convertPointsToRiyals() {
    setState(() {
      _riyals = _ecoPoints / 100;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadEcoPoints();
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
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Text(
              "Wallet",
              style: TextStyle(fontSize: 20,  fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 40),
            const Text(
              "You've Earned",
              style: TextStyle(fontSize: 18, color: Color(0xFF8063cb)),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/point.png", width: 30),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      "  $_ecoPoints ",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,

                      ),
                    ),
                    Text(
                      " Points ",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "balance :",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff177c39),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    if (_riyals > 0)
                      Text(
                        " ${_riyals.toStringAsFixed(2)} ",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff177c39),
                        ),
                      ),

                    const SizedBox(width: 5),
                    Image.asset("assets/s_riyal.png", width: 20),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 80),
            Text(
              "choose service: ",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8063cb),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 50),
              child: Row(
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.water_drop_outlined,
                          color: Color(0xFF8063cb),
                          size: 50,
                        ),

                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      Text(
                        "water bill",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8063cb),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.electric_bolt,
                          color: Color(0xFF8063cb),
                          size: 50,
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      Text(
                        "electricity bill",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8063cb),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    " pay with",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "نفاذ",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
