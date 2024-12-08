import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _mobileController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String verificationId = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Pasword'),
        automaticallyImplyLeading: false, // Removed the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(
                labelText: 'Enter Mobile Number (+91)',
                prefixText: '+91 ',
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                setState(() => isLoading = true);
                String phoneNumber =
                    '+91' + _mobileController.text.trim();
                final userCollection =
                FirebaseFirestore.instance.collection('users');

                QuerySnapshot querySnapshot = await userCollection
                    .where('mobileNumber', isEqualTo: phoneNumber)
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  try {
                    await _auth.verifyPhoneNumber(
                      phoneNumber: phoneNumber,
                      verificationCompleted:
                          (PhoneAuthCredential credential) async {},
                      verificationFailed: (FirebaseAuthException e) {
                        setState(() => isLoading = false);
                        print('Verification failed: ${e.message}');
                      },
                      codeSent:
                          (String verificationId, int? resendToken) {
                        setState(() => isLoading = false);
                        this.verificationId = verificationId;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnterOtpPage(
                              verificationId: verificationId,
                            ),
                          ),
                        );
                      },
                      codeAutoRetrievalTimeout:
                          (String verificationId) {},
                    );
                  } catch (e) {
                    setState(() => isLoading = false);
                    print('Phone verification failed: ${e.toString()}');
                  }
                } else {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Mobile number not registered')),
                  );
                }
              },
              child: Text('Send OTP'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil(
                        (route) => route.isFirst); // Return to login screen
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class EnterOtpPage extends StatefulWidget {
  final String verificationId;

  EnterOtpPage({required this.verificationId});

  @override
  _EnterOtpPageState createState() => _EnterOtpPageState();
}

class _EnterOtpPageState extends State<EnterOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter OTP'),
        automaticallyImplyLeading: false, // Removed the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Enter OTP',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                setState(() => isLoading = true);
                String otp = _otpController.text.trim();
                PhoneAuthCredential credential =
                PhoneAuthProvider.credential(
                  verificationId: widget.verificationId,
                  smsCode: otp,
                );

                try {
                  await FirebaseAuth.instance
                      .signInWithCredential(credential);
                  setState(() => isLoading = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewPasswordPage(),
                    ),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incorrect OTP')),
                  );
                  print('OTP verification failed: ${e.toString()}');
                }
              },
              child: Text('Confirm'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil(
                        (route) => route.isFirst); // Return to login screen
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class NewPasswordPage extends StatefulWidget {
  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _usernameController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter New Password'),
        automaticallyImplyLeading: false, // Removed the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'New Password',
              ),
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                setState(() => isLoading = true);
                String newPassword = _usernameController.text.trim();

                if (newPassword.isEmpty) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please enter a new password')),
                  );
                  return;
                }

                if (currentUser != null) {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('mobileNumber',
                      isEqualTo: currentUser!.phoneNumber)
                      .limit(1)
                      .get();

                  if (userDoc.docs.isNotEmpty) {
                    final docId = userDoc.docs.first.id;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update({'password': newPassword});
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Password updated successfully')),
                    );
                    Navigator.of(context).popUntil(
                            (route) => route.isFirst); // Return to login
                  } else {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User not found')),
                    );
                  }
                } else {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User not logged in')),
                  );
                }
              },
              child: Text('Confirm'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil(
                        (route) => route.isFirst); // Return to login screen
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}