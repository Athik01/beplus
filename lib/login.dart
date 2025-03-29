import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beplus/owner_home.dart';
import 'package:beplus/home_page.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
class LoginApp extends StatefulWidget {
  const LoginApp({Key? key}) : super(key: key);

  @override
  _LoginAppState createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  bool _loading = false;
  String _userType = '';

  Future<void> _registerWithGoogle() async {
    try {
      setState(() => _loading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'userType': _userType,
          'photoURL': user.photoURL,
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));

        // Delay navigation to avoid white screen flash
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_userType == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage2()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage1(user: user)),
            );
          }
        });
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Column(
            children: [
              // Hero image with fade effect
              Expanded(
                flex: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'heroImage',
                      child: Image.asset(
                        'lib/assets/be.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom container with buttons
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueGrey[900]!, Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      Text(
                        'The Future Looks Bright💡',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Step into tomorrow with BePlus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _userType = 'Admin');
                                _registerWithGoogle();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  side: BorderSide(color: Colors.grey[700]!),
                                ),
                                elevation: 8,
                                shadowColor: Colors.black38,
                              ),
                              child: const Text(
                                'Wholeseller',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _userType = 'User');
                                _registerWithGoogle();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: Colors.blueGrey[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  side: BorderSide(color: Colors.grey[500]!),
                                ),
                                elevation: 8,
                                shadowColor: Colors.black38,
                              ),
                              child: const Text(
                                'Retailer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Powered by JkEsteem',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Loading bar overlay
          if (_loading) const LoadingBarOverlay(),
        ],
      ),
    );
  }
}

class LoadingBarOverlay extends StatelessWidget {
  const LoadingBarOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Frosted glass effect background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0), // Soft blur effect
          child: Container(
            color: Colors.black.withOpacity(0.5), // Dark transparent overlay
          ),
        ),
        Column(
          children: [
            // Animated LinearProgressIndicator with gradient color
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.lightBlueAccent,
                  ),
                  minHeight: 5, // Slightly thicker for better visibility
                );
              },
            ),
            Expanded(
              child: Center(
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    'Signing in...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(1, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
