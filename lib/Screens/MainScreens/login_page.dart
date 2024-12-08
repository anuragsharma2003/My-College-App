import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlv_college/Screens/AdminHomePage/admin_login.dart';
import 'package:mlv_college/Screens/MainScreens/forgot_password_page.dart';
import 'package:mlv_college/Screens/MainScreens/forgot_username_page.dart';
import 'package:mlv_college/Screens/UserHomePage/user_signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlv_college/Screens/UserHomePage/user_dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isUsernameEmpty = false;
  bool _isPasswordEmpty = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isUsernameEmpty = _usernameController.text.isEmpty;
      _isPasswordEmpty = _passwordController.text.isEmpty;
    });

    if (_isUsernameEmpty || _isPasswordEmpty) {
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      String username = _usernameController.text.trim();
      String password = _passwordController.text;

      try {
        final userCollection = FirebaseFirestore.instance.collection('users');
        final querySnapshot = await userCollection
            .where('username', isEqualTo: username)
            .where('password', isEqualTo: password)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final userName = userDoc['name'];

          if (_rememberMe) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', username);
            await prefs.setString('password', password);
          }

          setState(() {
            _isSuccess = true;
          });

          await Future.delayed(Duration(seconds: 1)); // Short delay for the tick animation

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomePage(userName: userName),
            ),
          );
        } else {
          _showError('Incorrect username or password');
        }
      } catch (e) {
        _showError('Error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to the Admin Login page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminLoginPage()), // Adjust this based on your actual admin login page class name
              );
            },
            icon: Icon(Icons.admin_panel_settings),
            color: Colors.transparent, // Makes the icon invisible
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Color(0xFFF0F8FF), // Light blue background color
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 50), // Space between AppBar and MLVTEC
                          Text(
                            'MLVTEC',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 50), // Space between MLVTEC and text fields
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    validationMessage: 'Please enter your username',
                                    isError: _isUsernameEmpty,
                                  ),
                                  SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    validationMessage: 'Please enter your password',
                                    obscureText: _obscureText,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility : Icons.visibility_off,
                                      ),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    isError: _isPasswordEmpty,
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        checkColor: Colors.white, // Color of the check mark
                                        activeColor: Colors.blueAccent,
                                      ),
                                      Text('Remember Me', style: TextStyle(fontWeight: FontWeight.w100)),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  _isLoading
                                      ? _buildLoadingButton()
                                      : ElevatedButton(
                                    onPressed: _login,
                                    child: Text('Login', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.normal, fontSize: 17)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ForgotUsernamePage()),
                                          );
                                        },
                                        child: Text('Forgot Username?', style: TextStyle(fontFamily: 'Poppins', color: Colors.blueAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                                          );
                                        },
                                        child: Text('Forgot Password?', style: TextStyle(fontFamily: 'Poppins', color: Colors.blueAccent)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey,
                                          height: 36,
                                        ),
                                      ),
                                      Text(' or ', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey,
                                          height: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to the Signup page
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => UserSignupPage()), // Navigate to Signup page
                                      );

                                    },
                                    child: Text('Sign Up', style: TextStyle(fontFamily: 'Poppins', color: Colors.blueAccent)),
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(double.infinity, 50),
                                    ),
                                  ), // Add some space to the bottom if needed
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validationMessage,
    bool obscureText = false,
    Widget? suffixIcon,
    bool isError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 4), // changes position of shadow
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              labelStyle: TextStyle(color: Colors.black),
              suffixIcon: suffixIcon,
            ),
            obscureText: obscureText,
          ),
        ),
        // Error message outside the field with icon
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                SizedBox(width: 4),
                Text(
                  validationMessage,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Center(
          child: _isSuccess
              ? Icon(Icons.check, color: Colors.white, size: 30)
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}