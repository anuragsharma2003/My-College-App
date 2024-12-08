import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlv_college/Screens/AdminHomePage/admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true; // Manage password visibility
  bool _isLoading = false; // Manage loading state

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _adminLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      String adminUsername = _adminUsernameController.text;
      String adminPassword = _adminPasswordController.text;

      try {
        // Fetch admin credentials from Firestore
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('username', isEqualTo: adminUsername)
            .where('password', isEqualTo: adminPassword)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Credentials are correct, navigate to Admin Home Page
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else {
          // Handle invalid credentials
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid admin credentials')),
          );
        }
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging in: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _adminUsernameController,
                decoration: InputDecoration(labelText: 'Admin Username'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your admin username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _adminPasswordController,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                obscureText: _obscureText,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your admin password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _adminLogin,
                child: Text('Admin Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Set the background color to red
                  minimumSize: Size(double.infinity, 50), // Make the button slightly larger
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // More rounded corners
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

void main() {
  runApp(MaterialApp(
    home: AdminLoginPage(),
    routes: {
      '/admin_home': (context) => AdminHomePage(),
    },
  ));
}
