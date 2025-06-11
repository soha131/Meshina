import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'enter_otp.dart';
import 'forgetpassword.dart';
import 'package:flutter/gestures.dart';

class OtpScreen extends StatefulWidget {
  final String identifier;
  const OtpScreen({super.key, required this.identifier});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool isEmailSelected = true;
  bool _isEmail(String input) {
    return input.contains('@');
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  void _requestOtp() async {
    if (isEmailSelected && _isEmail(widget.identifier)) {
      try {
        await _auth.sendPasswordResetEmail(email: widget.identifier);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Password reset email sent!')));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnterOtpScreen(identifier: widget.identifier),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } else if (!isEmailSelected && !_isEmail(widget.identifier)) {
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: widget.identifier,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) {
            // optional: handle auto-retrieval
          },
          verificationFailed: (FirebaseAuthException e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.message}')),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => EnterOtpScreen(
                      identifier: widget.identifier,
                      verificationId: verificationId,
                    ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid input for selected method.')),
      );
    }
  }

  TapGestureRecognizer? _tapRecognizer;
  @override
  void initState() {
    super.initState();

    isEmailSelected = _isEmail(widget.identifier); // auto-select based on input

    _tapRecognizer = TapGestureRecognizer()..onTap = () {};
  }

  @override
  void dispose() {
    _tapRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          'REQUEST OTP',
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
                  MaterialPageRoute(
                    builder: (_) => const ForgetpasswordScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              // Email Option
              GestureDetector(
                onTap: () {
                  setState(() => isEmailSelected = true);
                },
                child: _otpOptionTile(
                  selected: isEmailSelected,
                  label: "Via Email",
                  value:
                      _isEmail(widget.identifier)
                          ? widget.identifier
                          : "Not available",
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // SMS Option
              GestureDetector(
                onTap: () {
                  setState(() => isEmailSelected = false);
                },
                child: _otpOptionTile(
                  selected: !isEmailSelected,
                  label: "Via SMS",
                  value:
                      !_isEmail(widget.identifier)
                          ? widget.identifier
                          : "Not available",
                  icon: Icons.phone_android_outlined,
                ),
              ),

              const SizedBox(height: 30),

              // Request OTP Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60.0),
                child: GestureDetector(
                  onTap: _requestOtp,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD8C4E8), Color(0xFF8E6BE8)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'REQUEST OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Footer Text
              Align(
                alignment: Alignment.bottomCenter,

                child: Padding(
                  padding: const EdgeInsets.only(right: 30, left: 30, top: 300),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF3D3B5E),
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'We sent you OTP to your register\nEmail/ Mobile number. If you didn’t get ',
                        ),
                        TextSpan(
                          text: 'click here',
                          style: const TextStyle(
                            color: Color(0xFF6D5BD0),
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _tapRecognizer,
                        ),
                      ],
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

  Widget _otpOptionTile({
    required bool selected,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FF),
        borderRadius: BorderRadius.circular(10),
        border:
            selected ? Border.all(color: Color(0xFF6D5BD0), width: 2) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8AACF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3D3B5E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Color(0xFFB8AACF)),
          const SizedBox(width: 10),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? Color(0xFF6D5BD0) : Color(0xFFB8AACF),
          ),
        ],
      ),
    );
  }
}
