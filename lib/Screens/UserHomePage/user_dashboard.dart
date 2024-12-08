import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatelessWidget {
  final String userName;

  UserHomePage({required this.userName});

  final List<String> imgList = [
    'assets/carousalimage2.png', // Replace with your image assets
    'assets/carousalimage1.png',
  ];

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');

    // Navigate back to the login page
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before exiting
        final bool exit = await _showExitConfirmationDialog(context);
        if (exit) {
          SystemNavigator.pop(); // Exit the app
          return true;
        }
        else {
          return false; // Return false to prevent the default back navigation
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent, // Set the color of the app bar
          automaticallyImplyLeading: false, // Remove the back button
          title: Row(
            children: [
              Lottie.asset(
                'assets/profile.json', // Replace with your Lottie animation asset
                width: 50, // Increased width
                height: 50, // Increased height
              ),
              Expanded(
                child: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18.0, // Slightly increased text size
                    fontWeight: FontWeight.w300, // Light font weight
                  ),
                  overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                  maxLines: 1, // Ensure text is on one line
                ),
              ),
              SizedBox(width: 20.0), // Gap between user's name and "Log Out"
              GestureDetector(
                onTap: () {
                  _logout(context); // Call the logout method
                },
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Slider with no top padding
            Container(
              color: Colors.white70, // Light white background for the slider
              child: CarouselSlider(
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.width * 0.7, // Decreased slider height
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
                items: imgList.map((item) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 20.0), // Add margin to avoid touching the container
                  width: MediaQuery.of(context).size.width, // Ensure the width matches the height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.asset(item, fit: BoxFit.cover),
                  ),
                )).toList(),
              ),
            ),

            // Categories Text with Bold Line Below
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0, // Increased text size
                    ),
                  ),
                  SizedBox(height: 8.0), // Space between text and line
                  Container(
                    height: 4.0, // Increased thickness
                    width: 150, // Adjust this value to match the width of the text
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // Notification Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: EdgeInsets.all(12.0), // Reduced padding around grid
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 3 / 2, // Adjusted aspect ratio to make buttons smaller
                children: [
                  _buildGridButton(context, Icons.notifications, 'View Notifications', '/notifications'),
                  _buildGridButton(context, Icons.school, 'Student Updates', '/view_students_updates'), // Ensure correct route
                  _buildGridButton(context, Icons.event, 'Upcoming Events', '/view_upcoming_events'), // Updated route
                  _buildGridButton(context, Icons.article, 'Newsletters', '/newsletters'),
                  _buildGridButton(context, Icons.photo_album, 'Gallery', '/gallery'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final bool? exit = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exit'),
          content: Text('Do you really want to exit the app?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false to not exit
              },
            ),
            TextButton(
              child: Text('Exit'),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true to exit
              },
            ),
          ],
        );
      },
    );

    return exit ?? false; // Return false if dialog is dismissed by tapping outside
  }

  Widget _buildGridButton(BuildContext context, IconData icon, String title, String route) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36.0, color: Colors.blueAccent), // Icon color blue
          SizedBox(height: 8.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', color: Colors.blueAccent, fontSize: 16.0),
          ),
        ],
      ),
    );
  }
}