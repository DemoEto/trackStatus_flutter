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
  final TextEditingController _controllerConfirmPassword = TextEditingController();
  final TextEditingController _controllerName = TextEditingController();

  @override
  void dispose() {
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerConfirmPassword.dispose();
    _controllerName.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    try {
      await AuthService().signIn(
        email: _controllerEmail.text.trim(),
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

  Future<void> _handleRegister() async {
    if (_controllerPassword.text != _controllerConfirmPassword.text) {
      setState(() {
        errorMessage = 'Passwords do not match.';
      });
      return;
    }
    
    if (_controllerName.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter your name.';
      });
      return;
    }
    
    try {
      await AuthService().register(
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text,
        displayName: _controllerName.text.trim(),
      );
      
      if (mounted) {
        _controllerPassword.clear();
        _controllerConfirmPassword.clear();
        _controllerName.clear();
        setState(() {
          errorMessage = 'Registration successful! Please log in.';
          isLogin = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _buildErrorMessage() {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: isLogin ? _handleSignIn : _handleRegister,
        child: Text(
          isLogin ? 'Login' : 'Register',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleAuthButton() {
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

  Widget _buildInputField({
    required String labelText,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          labelText: labelText,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 197, 211, 232),
              Color.fromARGB(255, 156, 179, 216),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
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
                    const SizedBox(height: 24),
                    Text(
                      isLogin ? "Welcome Back!" : "Create Account",
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
                          : "Create a new account to get started",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      labelText: "Email Address",
                      controller: _controllerEmail,
                      icon: FontAwesomeIcons.envelope,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        // Simple email validation
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      labelText: "Password",
                      controller: _controllerPassword,
                      isPassword: true,
                      icon: FontAwesomeIcons.lock,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!isLogin) ...[
                      _buildInputField(
                        labelText: "Confirm Password",
                        controller: _controllerConfirmPassword,
                        isPassword: true,
                        icon: FontAwesomeIcons.lock,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _controllerPassword.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      _buildInputField(
                        labelText: "Full Name",
                        controller: _controllerName,
                        icon: FontAwesomeIcons.user,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: implement Forgot Password logic
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    _buildErrorMessage(),
                    const SizedBox(height: 16),
                    _buildSubmitButton(),
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
                    const SizedBox(height: 12),
                    _buildSocialLoginButtons(),
                    const SizedBox(height: 16),
                    _buildToggleAuthButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
