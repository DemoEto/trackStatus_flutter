import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';

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
        // Instead of navigating directly, we'll let the router handle the redirect
        // The GoRouter will handle the redirect based on user role
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
        displayName: _controllerName.text,
      );
      if (mounted) {
        _controllerPassword.clear();
        _controllerConfirmPassword.clear();
        _controllerName.clear();
      }
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
            color: Colors.black54,
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 197, 211, 232),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: screenWidth * 0.9,
              constraints: BoxConstraints(
                maxWidth: 400, // Maximum width for better UX on large screens
                maxHeight: screenHeight * 0.85, // Limit height for better UX
              ),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 120,
                      width: 120,
                      child: Image(
                        image: AssetImage("assets/images/login2.png"),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isLogin ? "Hello" : "Create Account",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 20),
                  _entryField(
                    context,
                    "Email Address",
                    _controllerEmail,
                    icon: FontAwesomeIcons.envelope,
                  ),
                  const SizedBox(height: 10),
                  _entryField(
                    context,
                    "Password",
                    _controllerPassword,
                    isPassword: true,
                    icon: FontAwesomeIcons.eyeSlash,
                  ),
                  if (!isLogin) ...[
                    const SizedBox(height: 10),
                    _entryField(
                      context,
                      "Confirm Password",
                      _controllerConfirmPassword,
                      isPassword: true,
                      icon: FontAwesomeIcons.eye,
                    ),
                    const SizedBox(height: 10),
                    _entryField(
                      context,
                      "Full Name",
                      _controllerName,
                      icon: FontAwesomeIcons.user,
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: implement Forget Password logic
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  _errorMessage(),
                  const SizedBox(height: 20),
                  _submitButton(context),
                  const SizedBox(height: 20),
                  const Text(
                    "Or sign in with",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  _socialLoginButtons(context),
                  const SizedBox(height: 15),
                  _loginOrRegisterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
