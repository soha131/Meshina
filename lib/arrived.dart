import 'package:flutter/material.dart';

class ArrivedScreen extends StatelessWidget {
  final String transportMode;

  const ArrivedScreen({super.key, required this.transportMode});

  @override
  Widget build(BuildContext context) {
    IconData startIcon = _getStartIcon(transportMode);
    Color startColor = _getIconColor(transportMode);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Arrived!",
                      style: TextStyle(fontSize: 24, color: Colors.black, fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,),
                    ),
                    SizedBox(height: 100),
                    SizedBox(
                      width: 250,
                      height: 300,
                      child: CustomPaint(
                        painter: RoutePainter(),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Icon(
                                startIcon,
                                size: 40,
                                color: startColor,
                              ),
                            ),
                            Positioned(
                              right: -10,
                              top: 0,
                              child: Icon(
                                Icons.flag,
                                size: 40,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 18, color: Colors.black),
                        children: _buildArrivalText(transportMode),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStartIcon(String transportMode) {
    switch (transportMode) {
      case "WALK":
        return Icons.directions_walk;
      case "Bicycle":
        return Icons.directions_bike;
      case "Bus":
      case "transit":
      case "metro":
        return Icons.directions_bus;
      case "CAR":
        return Icons.directions_car;
      default:
        return Icons.flag;
    }
  }

  Color _getIconColor(String transportMode) {
    switch (transportMode) {
      case "WALK":
      case "Bicycle":
        return Color(0xff518b38);
      case "Bus":
      case "transit":
      case "metro":
        return Colors.blue;
      case "CAR":
        return Color(0xFF8063cb);
      default:
        return Colors.black;
    }
  }

  List<TextSpan> _buildArrivalText(String transportMode) {
    Color startColor = _getIconColor(transportMode);
    switch (transportMode) {
      case "walking":
      case "WALK":
      case "Bicycle":
      case "Bus":
      case "transit":
      case "metro":
        return [
          const TextSpan(text: "!الحمدلله على السلامة "),
          TextSpan(
            text: "كسبت نقاط",
            style: TextStyle(color: startColor, fontWeight: FontWeight.bold),
          ),
        ];
      case "CAR":
        return [
          const TextSpan(text: "الحمدلله على السلامة "),
          TextSpan(
            text: "\n!جرب خيار أوفر المرة الجاية",
            style: TextStyle(color: startColor, fontWeight: FontWeight.bold),
          ),
        ];
      default:
        return [const TextSpan(text: "الحمدلله على السلامة!")];
    }
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    Path path = Path();
    path.moveTo(20, size.height - 40);

    path.quadraticBezierTo(
      size.width / 4,
      size.height / 2,
      size.width / 2,
      size.height / 1.5,
    );
    path.quadraticBezierTo(
      3 * size.width / 4,
      size.height / 3,
      size.width - 20,
      40,
    );

    drawDashedPath(canvas, path, paint);
  }

  void drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5;
    const dashSpace = 5;
    double distance = 0.0;
    final pathMetrics = path.computeMetrics();
    for (var pathMetric in pathMetrics) {
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
