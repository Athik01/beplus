import 'dart:async';
import 'dart:ui'; // Import for ImageFilter
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:beplus/login.dart';
import 'owner_home.dart';
import 'home_page.dart'; // Import the home page

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _loading = false;
  String _userType = 'User'; // Default user type

  late AnimationController controller1;
  late AnimationController controller2;
  late Animation<double> animation1;
  late Animation<double> animation2;
  late Animation<double> animation3;
  late Animation<double> animation4;

  @override
  void initState() {
    super.initState();

    controller1 = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );
    animation1 = Tween<double>(begin: .1, end: .15).animate(
      CurvedAnimation(
        parent: controller1,
        curve: Curves.easeInOut,
      ),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller1.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller1.forward();
        }
      });
    animation2 = Tween<double>(begin: .02, end: .04).animate(
      CurvedAnimation(
        parent: controller1,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {});
    });

    controller2 = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );
    animation3 = Tween<double>(begin: .41, end: .38).animate(CurvedAnimation(
      parent: controller2,
      curve: Curves.easeInOut,
    ))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller2.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller2.forward();
        }
      });
    animation4 = Tween<double>(begin: 170, end: 190).animate(
      CurvedAnimation(
        parent: controller2,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {});
    });

    Timer(Duration(milliseconds: 2500), () {
      controller1.forward();
    });

    controller2.forward();
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
  //
  Future<void> _registerWithGoogle() async {
    try {
      setState(() {
        _loading = true;
      });

      // Initiating Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _loading = false;
        });
        return; // User canceled the sign-in process
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Generating Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Signing in with Firebase using the Google credentials
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Fetching the user
      final user = userCredential.user;
      if (user != null) {
        // Storing user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'userType': _userType, // Store selected user type
          'photoURL': user.photoURL,
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true)); // Merge if the document already exists

        // Redirecting user based on userType
        if (_userType == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage2()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage1(user: user),
            ),
          );
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print('Error during Google Sign-In: $e');
      // Show error message to the user
    }
  }

  Future<void> _signup() async {
    setState(() {
      _loading = true;
    });

    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'mobile': _mobileController.text,
        'userType': _userType, // Add userType to Firestore
      });

      // Show a toast message to inform the user to verify their email
      Fluttertoast.showToast(msg: 'Verification email sent. Please check your inbox.');

      // Optionally navigate to a different page or show a dialog
      // For now, let's just clear the fields
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _mobileController.clear();

      // You might want to add a way to navigate to a different page after email verification
      // For example, you could navigate to a login page or a message page instructing them to verify their email
    } catch (e) {
      Fluttertoast.showToast(msg: 'Signup Failed: ${e.toString()}');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xff192028),
      body: Stack(
        children: [
          Positioned(
            top: size.height * (animation2.value + .58),
            left: size.width * .21,
            child: CustomPaint(
              painter: MyPainter(50),
            ),
          ),
          Positioned(
            top: size.height * .98,
            left: size.width * .1,
            child: CustomPaint(
              painter: MyPainter(animation4.value - 30),
            ),
          ),
          Positioned(
            top: size.height * .5,
            left: size.width * (animation2.value + .8),
            child: CustomPaint(
              painter: MyPainter(30),
            ),
          ),
          Positioned(
            top: size.height * .5,
            left: size.width * (animation2.value + .8),
            child: CustomPaint(
              painter: MyPainter(30),
            ),
          ),
          Positioned(
            top: size.height * .1,
            left: size.width * .8,
            child: CustomPaint(
              painter: MyPainter(animation4.value),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05), // Adjust padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New Registration',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.7),
                    fontSize: size.width * 0.08, // Responsive font size
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    wordSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 10),

                // User Type Selection Container
                Container(
                  height: size.width / 8,
                  width: size.width * 0.9, // Responsive width
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _userType = 'User';
                            });
                          },
                          child: Container(
                            color: _userType == 'User'
                                ? Colors.white.withOpacity(0.3) // Brighter highlight for selection
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              'User',
                              style: TextStyle(
                                color: _userType == 'User'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.8), // Brighter text for selection
                                fontSize: 14,
                                fontWeight: FontWeight.bold, // Bold text
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _userType = 'Admin';
                            });
                          },
                          child: Container(
                            color: _userType == 'Admin'
                                ? Colors.white.withOpacity(0.3) // Brighter highlight for selection
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                color: _userType == 'Admin'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.8), // Brighter text for selection
                                fontSize: 14,
                                fontWeight: FontWeight.bold, // Bold text
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                component1(Icons.person_outline, 'Name...', false, false, _nameController),
                const SizedBox(height: 10),
                component1(Icons.email_outlined, 'Email...', false, true, _emailController),
                const SizedBox(height: 10),
                component1(Icons.lock_outline, 'Password...', true, false,
                    _passwordController),
                const SizedBox(height: 10),
                component1(Icons.phone_outlined, 'Mobile Number...', false, false,
                    _mobileController),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(size.width * 0.8, 50), // Responsive width
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey.withOpacity(0.3), // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0, // Remove shadow if desired
                    padding: EdgeInsets.symmetric(vertical: 15), // Adjust padding as needed
                  ),
                  child: _loading
                      ? CircularProgressIndicator()
                      : Text('Signup', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),

                // Register with Google Button
                ElevatedButton.icon(
                  onPressed: _registerWithGoogle, // Your Google login function
                  icon: Image.network(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQjzC2JyZDZ_RaWf0qp11K0lcvB6b6kYNMoqtZAQ9hiPZ4cTIOB&psig=AOvVaw0wSJfTqvDbyOTlEbgiBmvV&ust=1732901738429000&source=images&cd=vfe&opi=89978449&ved=0CBAQjRxqFwoTCLiKxpbI_4kDFQAAAAAdAAAAABAE',
                    height: 24, // Adjust the size as needed
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(color: Colors.black), // Google text color
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(size.width * 0.8, 50), // Responsive width
                    backgroundColor: Colors.white, // Button color (white background)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Rounded corners
                    ),
                    elevation: 5, // Add a shadow effect if desired
                    side: BorderSide(color: Colors.blueAccent), // Border color
                  ),
                ),

                const SizedBox(height: 10),
                GestureDetector(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(size.width * 0.8, 50), // Responsive width
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey.withOpacity(0.3), // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0, // Remove shadow if desired
                      padding: EdgeInsets.symmetric(vertical: 15), // Adjust padding as needed
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginApp()),
                      );
                    },
                    child: Text('Already have an account? Login',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity, // Full width
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Padding
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3), // Warning background color
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                    border: Border.all(color: Colors.redAccent, width: 1.5), // Border for prominence
                  ),
                  child: Text(
                    '⚠ Select the Account Type and Enter Password before Google Sign In',
                    textAlign: TextAlign.center, // Center-align the text
                    style: TextStyle(
                      color: Colors.white, // White text for contrast
                      fontSize: 15,
                      fontWeight: FontWeight.bold, // Bold for emphasis
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget component1(IconData icon, String hintText, bool isPassword,
      bool isEmail, TextEditingController controller) {
    Size size = MediaQuery.of(context).size;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaY: 15,
          sigmaX: 15,
        ),
        child: Container(
          height: size.width / 8,
          width: size.width / 1.2,
          alignment: Alignment.center,
          padding: EdgeInsets.only(right: size.width / 30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white.withOpacity(.8)),
            cursorColor: Colors.white,
            obscureText: isPassword,
            keyboardType:
            isEmail ? TextInputType.emailAddress : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(.7),
              ),
              border: InputBorder.none,
              hintMaxLines: 1,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(.5)),
            ),
          ),
        ),
      ),
    );
  }
}