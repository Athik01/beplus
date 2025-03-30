import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:beplus/home_page.dart';
import 'package:beplus/login.dart';
import 'firebase_options.dart';
import 'owner_home.dart';
import 'dart:async';
import 'package:flutter/material.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully.');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jk Esteem️..!🏃‍➡️',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Start with Netflix-style splash screen
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Auth
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is signed in, retrieve user data
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error loading user data'),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            var userType = snapshot.data!.get('userType');
            if (userType == 'Admin') {
              return HomePage2(); // If the user is an admin
            } else {
              return HomePage1(user: user); // If the user is a regular user
            }
          }

          // Fallback to login if user type not found
          return LoginApp();
        },
      );
    } else {
      // No user logged in — show login page
      return LoginApp();
    }
  }
}

// Function to start performance tracing (optional)
void startPerformanceTrace() async {
  final Trace trace = FirebasePerformance.instance.newTrace('auth_wrapper_trace');
  trace.start();

  // Simulating some work
  await Future.delayed(Duration(seconds: 1));

  trace.stop();
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _mainFadeAnimation;
  late Animation<double> _mainScaleAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    // Main title animations: scale & fade (first half of the timeline).
    _mainScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _mainFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Tagline animations: slide from bottom and fade in (later in the timeline).
    _taglineSlideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Animated background gradient from deep purple to near-black.
    _backgroundAnimation = ColorTween(
      begin: Colors.deepPurple,
      end: Colors.black87,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.forward();

    // Transition to next screen after a brief delay (after the animations complete).
    Timer(Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _backgroundAnimation.value!,
                  Colors.black87,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main title with scale and fade animations.
                  FadeTransition(
                    opacity: _mainFadeAnimation,
                    child: ScaleTransition(
                      scale: _mainScaleAnimation,
                      child: Text(
                        'Jk Esteem',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 20.0,
                              color: Colors.redAccent.withOpacity(0.8),
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Tagline with slide and fade animations.
                  SlideTransition(
                    position: _taglineSlideAnimation,
                    child: FadeTransition(
                      opacity: _taglineFadeAnimation,
                      child: Text(
                        "Let's Connect Easy!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}