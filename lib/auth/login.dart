import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meshina_app/auth/pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CreatePinScreen.dart';
import '../cubit/AuthCubit.dart';
import '../cubit/auth_state.dart';
import 'forgetpassword.dart';
import 'signup.dart';
import '../onboarding/welcome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return
     Scaffold(
        backgroundColor: Colors.white,
        body: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthLoading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
            } else if (state is AuthSuccess) {
              Navigator.pop(context); // remove loading
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CreatePinScreen()),
              );
            } else if (state is AuthError) {
              Navigator.pop(context); // remove loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric( vertical: 15),
              child: Column(
                children: [
                   Column(
                      children: [
                        Image.asset(
                          'assets/appbar.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        ),
                        SizedBox(height: 10,),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only( left: 180,right: 100),
                              child: const Text(
                                'LOG IN',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF2F1532),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 28,
                                color: Color(0xFFACA3CF),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Username or Email',
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFFACA3CF),
                                    ),
                                    suffixIcon: Icon(
                                      Icons.person_outline,
                                      color: Color(0xFFACA3CF),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFACA3CF)),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF9087CC),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? 'Enter a username'
                                              : null,
                                ),
                                const SizedBox(height: 20),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFFACA3CF),
                                    ),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFACA3CF)),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF9087CC),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.lock : Icons.lock_open,
                                        color: Color(0xFFACA3CF),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.length < 6
                                              ? 'Invalid Password'
                                              : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                final email = _usernameController.text.trim();
                                final password = _passwordController.text.trim();
                                context.read<AuthCubit>().loginWithEmail(
                                  email,
                                  password,
                                );
                              }
                            },
                            child: Container(
                              height: 50,
                              width: 300,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFDCC2FF), Color(0xFF9386FC)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'LOG IN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final storedPin = prefs.getString('user_pin');

                                  if (storedPin != null && storedPin.isNotEmpty) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PinScreen(),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WelcomeScreen(),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Login using Pin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFACA3CF),
                                  ),
                                ),
                              ),
                              const Text(
                                '|',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFACA3CF),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignUpScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Create New Account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFACA3CF),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Expanded(
                                child: Divider(
                                  thickness: 2,
                                  indent: 40,
                                  endIndent: 10,
                                  color: Color(0xFF6B6787),
                                ),
                              ),
                              Text("Or", style: TextStyle(color: Color(0xFFACA3CF))),
                              Expanded(child: Divider(thickness: 2, indent: 10, endIndent: 40, color: Color(0xFF6B6787),)),
                            ],
                          ),

                          const SizedBox(height: 30),
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                final GoogleSignInAccount? googleUser =
                                    await GoogleSignIn().signIn();
                                if (googleUser == null) return;

                                final GoogleSignInAuthentication googleAuth =
                                    await googleUser.authentication;

                                final credential = GoogleAuthProvider.credential(
                                  accessToken: googleAuth.accessToken,
                                  idToken: googleAuth.idToken,
                                );

                                final userCredential = await FirebaseAuth.instance
                                    .signInWithCredential(credential);
                                final user = userCredential.user;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Google sign-in error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide.none,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              "Google",
                              style: TextStyle(fontSize: 15, color: Color(0xFFACA3CF)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide.none,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              "Nafath",
                              style: TextStyle(fontSize: 15, color: Color(0xFFACA3CF)),
                            ),
                          ),
                          const SizedBox(height: 120),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignUpScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Create an Account",
                                  style: TextStyle(color: Color(0xFFACA3CF)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ForgetpasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(color: Color(0xFFACA3CF)),
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
          ),

    );
  }
}
