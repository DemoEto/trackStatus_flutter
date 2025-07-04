import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage;
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword =
      TextEditingController();
  final TextEditingController _controllerName = TextEditingController();

  @override
  void dispose() {
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerConfirmPassword.dispose();
    _controllerName.dispose();
    super.dispose();
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await AuthService().signIn(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String uid = user.uid;
        final String prefix = uid.substring(0, 1).toLowerCase();

        if (prefix == 't') {
          Navigator.pushReplacementNamed(context, '/teacherAttendanceView');
        } else if (prefix == 's') {
          Navigator.pushReplacementNamed(context, '/studentAttendanceView');
        } else if (prefix == 'p') {
          Navigator.pushReplacementNamed(context, '/parentAttendanceView');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถระบุประเภทผู้ใช้จาก UID ได้'),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (_controllerPassword.text != _controllerConfirmPassword.text) {
      setState(() {
        errorMessage = 'Passwords do not match.';
      });
      return;
    }
    try {
      await AuthService().register(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      // ✅ บันทึกชื่อผู้ใช้ใน Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({ 
          'uid': user.uid,
          'email': user.email,
          'name': _controllerName.text,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() {
        isLogin = true;
        errorMessage = 'Register success! Please login.';
      });

      _controllerPassword.clear();
      _controllerConfirmPassword.clear();
      _controllerName.clear();

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _errorMessage() {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      errorMessage!,
      style: const TextStyle(color: Colors.red, fontSize: 16),
      textAlign: TextAlign.center,
    );
  }

  Widget _submitButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth * 0.8,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        onPressed: () {
          isLogin
              ? signInWithEmailAndPassword()
              : createUserWithEmailAndPassword();
        },
        child: Text(
          isLogin ? 'Login' : 'Register',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
          errorMessage = null;
        });
      },
      child: Text(
        isLogin ? 'Create an account' : 'Already have an account? Login',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _entryField(
    BuildContext context,
    String labelText,
    TextEditingController controller, {
    bool isPassword = false,
    IconData? icon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          icon: icon != null ? Icon(icon, color: Colors.grey, size: 22) : null,
          labelText: labelText,
          labelStyle: const TextStyle(fontSize: 16, color: Colors.grey),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _socialLoginButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            // TODO: implement Facebook login
          },
          icon: const Icon(
            FontAwesomeIcons.facebook,
            color: Colors.blue,
            size: 30,
          ),
        ),
        IconButton(
          onPressed: () async {
            try {
              // TODO: implement Google Sign-in logic here
            } catch (e) {
              setState(() {
                errorMessage = 'Failed to sign in with Google.';
              });
            }
          },
          icon: const Icon(
            FontAwesomeIcons.google,
            color: Colors.redAccent,
            size: 30,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: implement Twitter login
          },
          icon: const Icon(
            FontAwesomeIcons.twitter,
            color: Colors.orangeAccent,
            size: 30,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: implement LinkedIn login
          },
          icon: const Icon(
            FontAwesomeIcons.linkedinIn,
            color: Colors.green,
            size: 30,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Container(
            width: screenWidth,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 197, 211, 232),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.04),
                SizedBox(
                  height: screenHeight * 0.2,
                  width: screenWidth * 0.6,
                  child: Image.asset("assets/images/login2.png"),
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin ? "Hello" : "Create Account",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLogin
                              ? "Please Login to Your Account"
                              : "Create a new account",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        _entryField(
                          context,
                          "Email Address",
                          _controllerEmail,
                          icon: FontAwesomeIcons.envelope,
                        ),
                        const SizedBox(height: 5),
                        _entryField(
                          context,
                          "Password",
                          _controllerPassword,
                          isPassword: true,
                          icon: FontAwesomeIcons.eyeSlash,
                        ),
                        if (!isLogin)
                          Column(
                            children: [
                              const SizedBox(height: 5),
                              _entryField(
                                context,
                                "Confirm Password",
                                _controllerConfirmPassword,
                                isPassword: true,
                                icon: FontAwesomeIcons.eye,
                              ),
                              const SizedBox(height: 5),
                              _entryField(
                                context,
                                "First - Last name",
                                _controllerName,
                                icon: FontAwesomeIcons.user,
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isLogin)
                                TextButton(
                                  onPressed: () {
                                    // TODO: implement Forget Password logic
                                  },
                                  child: const Text(
                                    "Forget Password",
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _errorMessage(),
                        const SizedBox(height: 15),
                        _submitButton(context),
                        const SizedBox(height: 10),
                        const Text(
                          "Or Login using Social Media Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        _socialLoginButtons(context),
                        _loginOrRegisterButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
