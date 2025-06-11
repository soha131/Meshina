import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'new_password.dart';
import 'login.dart';

class EnterOtpScreen extends StatefulWidget {
  final String identifier;
  final String? verificationId;
  const EnterOtpScreen({super.key, required this.identifier, this.verificationId});

  @override
  State<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends State<EnterOtpScreen> {
  List<String> otpDigits = ['', '', '', ''];

  void _addDigit(String digit) {
    for (int i = 0; i < otpDigits.length; i++) {
      if (otpDigits[i].isEmpty) {
        setState(() {
          otpDigits[i] = digit;
        });
        break;
      }
    }
  }

  void _removeDigit() {
    for (int i = otpDigits.length - 1; i >= 0; i--) {
      if (otpDigits[i].isNotEmpty) {
        setState(() {
          otpDigits[i] = '';
        });
        break;
      }
    }
  }
  Widget _buildOtpBox(String digit) {
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          Text(
            digit,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            color: Color(0xFF3D3B5E),
          ),
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
        child: isBackspace
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
          'ENTER OTP',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF2F1532),
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
        child:Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: otpDigits.map((digit) => _buildOtpBox(digit)).toList(),
                ),const SizedBox(height: 30),

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
                        for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
                        _buildKeypadButton('', isBackspace: false), // empty
                        _buildKeypadButton('0'),
                        _buildKeypadButton('', isBackspace: true),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    String otpCode = otpDigits.join();

                    if (otpCode.length != 6 && otpCode.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter a valid OTP")),
                      );
                      return;
                    }

                    if (widget.verificationId != null) {
                      // SMS-based OTP
                      try {
                        PhoneAuthCredential credential = PhoneAuthProvider.credential(
                          verificationId: widget.verificationId!,
                          smsCode: otpCode,
                        );

                        // You can sign in or just verify the user to allow password reset flow
                        await FirebaseAuth.instance.signInWithCredential(credential);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => NewPasswordScreen(identifier: widget.identifier)),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Invalid OTP. Please try again.")),
                        );
                      }
                    } else {
                      // Email flow – assume user got a reset link
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => NewPasswordScreen(identifier: widget.identifier)),
                      );
                    }
                  },
                  child: Container(
                    height: 60,
                    width: 250,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD1E87F), Color(0xFF91B24C)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'CONFIRM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
      const SizedBox(height: 20),

      // Resend OTP
      const Text(
        'Resend OTP',
        style: TextStyle(
          color: Color(0xFF9E93C9),
          fontWeight: FontWeight.w500,
        ),)
              ],

        ),
      ),
    );
  }
}
