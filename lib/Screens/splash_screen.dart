import 'package:flutter/material.dart';
import 'package:mlv_college/Screens/UserHomePage/user_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MainScreens/login_page.dart'; // Import UserHomePage

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');
    String? savedPassword = prefs.getString('password');

    await Future.delayed(Duration(seconds: 2), () {}); // Simulate a delay for splash effect

    if (savedUsername != null && savedPassword != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserHomePage(userName: savedUsername),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                child: Image.asset("assets/ic_launcher_round.png"),
              ),
              SizedBox(height: 20),
              Text(
                'MLV Textile & Engineering College',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}