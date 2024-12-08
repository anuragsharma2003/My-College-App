import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnterOtpPage extends StatefulWidget {
  final String name;
  final String username;
  final String password;
  final String mobileNumber;
  final String verificationId;

  EnterOtpPage({
    required this.name,
    required this.username,
    required this.password,
    required this.mobileNumber,
    required this.verificationId,
  });

  @override
  _EnterOtpPageState createState() => _EnterOtpPageState();
}

class _EnterOtpPageState extends State<EnterOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _otp = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter OTP'),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false, // Hides the back button
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  _buildTextField(
                    label: 'Enter OTP',
                    validationMessage: 'Please enter the OTP sent to your mobile number',
                    onSaved: (value) => _otp = value!,
                  ),
                  SizedBox(height: 20),
                  if (_isLoading) ...[
                    CircularProgressIndicator(), // Show loader
                  ] else ...[
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          await _verifyOtpAndCreateAccount();
                        }
                      },
                      child: Text('Create Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String validationMessage,
    required Function(String?) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return validationMessage;
            }
            return null;
          },
          onSaved: onSaved,
        ),
      ),
    );
  }

  Future<void> _verifyOtpAndCreateAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create PhoneAuthCredential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );

      // Sign in with credential
      await _auth.signInWithCredential(credential);

      // Create the account in Firestore
      await _firestore.collection('users').add({
        'name': widget.name,
        'username': widget.username,
        'password': widget.password,
        'mobileNumber': widget.mobileNumber,
      });

      // Show success message and navigate to the login page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully. Please log in.')),
      );

      // Navigate to the login page
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Failed to verify OTP: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}