import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import '../main_map.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  List<String> pinDigits = ['', '', '', ''];

  void _addDigit(String digit) {
    for (int i = 0; i < pinDigits.length; i++) {
      if (pinDigits[i].isEmpty) {
        setState(() {
          pinDigits[i] = digit;
        });
        break;
      }
    }
  }

  void _removeDigit() {
    for (int i = pinDigits.length - 1; i >= 0; i--) {
      if (pinDigits[i].isNotEmpty) {
        setState(() {
          pinDigits[i] = '';
        });
        break;
      }
    }
  }

  Widget _buildPinBox(String digit) {
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          Text(
            digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(height: 2, color: Color(0xFF3D3B5E)),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isBackspace = false}) {
    return InkWell(
      onTap: () {
        isBackspace ? _removeDigit() : _addDigit(value);
      },
      child: Container(
        alignment: Alignment.center,
        child:
            isBackspace
                ? const Icon(Icons.backspace_outlined, color: Color(0xFF3D3B5E))
                : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF3D3B5E),
                  ),
                ),
      ),
    );
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');
    final enteredPin =  pinDigits.join();
    if (!mounted) return;
    if (enteredPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("من فضلك أدخل PIN")),
      );
      return;
    }
    if (enteredPin == savedPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid PIN")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          'Enter PIN',
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                pinDigits.map((digit) => _buildPinBox(digit)).toList(),
              ),
              const SizedBox(height: 30),

              // Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      for (var i = 1; i <= 9; i++)
                        _buildKeypadButton(i.toString()),
                      _buildKeypadButton('', isBackspace: false), // empty
                      _buildKeypadButton('0'),
                      _buildKeypadButton('', isBackspace: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap:_checkPin,
                child: Container(
                  height: 60,
                  width: 250,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDCC2FF), Color(0xFF9386FC)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Unlock',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
