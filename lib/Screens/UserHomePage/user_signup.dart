import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enter_otp.dart';

class UserSignupPage extends StatefulWidget {
  @override
  _UserSignupPageState createState() => _UserSignupPageState();
}

class _UserSignupPageState extends State<UserSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = '';
  String _username = '';
  String _password = '';
  String _mobileNumber = '';
  bool _isOtpSent = false;
  String _verificationId = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Signup'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  if (!_isOtpSent) ...[
                    _buildTextField(
                      'Name',
                      'Please enter your name',
                          (value) => _name = value!,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      'Username',
                      'Please enter your username',
                          (value) => _username = value!,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      'Password',
                      'Please enter your password',
                          (value) => _password = value!,
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    _buildMobileNumberField(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          await _checkAndSendOtp();
                        }
                      },
                      child: Text('Send OTP'),
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

  Widget _buildTextField(
      String label,
      String validationMessage,
      Function(String?) onSaved, {
        bool obscureText = false,
        TextInputType? keyboardType,
        String? hintText,
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
            hintText: hintText,
            border: InputBorder.none,
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
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

  Widget _buildMobileNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '+91 ',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter your mobile number',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 10) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
                onChanged: (value) {
                  _mobileNumber = '+91' + value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAndSendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: _username)
          .get();
      var mobileNumberSnapshot = await _firestore
          .collection('users')
          .where('mobileNumber', isEqualTo: _mobileNumber)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username already registered')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (mobileNumberSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mobile number already registered')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _sendOtp();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _sendOtp() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _mobileNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          setState(() {
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnterOtpPage(
                name: _name,
                username: _username,
                password: _password,
                mobileNumber: _mobileNumber,
                verificationId: _verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}