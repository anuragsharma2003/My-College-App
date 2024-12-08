import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mlv_college/Screens/AdminHomePage/AddUpdates/add_upcoming_event.dart';
import 'package:mlv_college/Screens/AdminHomePage/ManageUpdates/manage_gallery_item.dart';
import 'package:mlv_college/Screens/AdminHomePage/ManageUpdates/manage_newsletter.dart';
import 'package:mlv_college/Screens/AdminHomePage/ManageUpdates/manage_notification.dart';
import 'package:mlv_college/Screens/AdminHomePage/ManageUpdates/manage_students_update.dart';
import 'package:mlv_college/Screens/AdminHomePage/AddUpdates/add_gallery_item.dart';
import 'package:mlv_college/Screens/AdminHomePage/AddUpdates/add_newsletter.dart';
import 'package:mlv_college/Screens/AdminHomePage/AddUpdates/add_notifications_page.dart';
import 'package:mlv_college/Screens/AdminHomePage/admin_dashboard.dart';
import 'package:mlv_college/Screens/AdminHomePage/admin_login.dart';
import 'package:mlv_college/Screens/AdminHomePage/ManageUpdates/manage_upcoming_event.dart';
import 'package:mlv_college/Screens/UserHomePage/ViewUpdates/view_newsletters.dart';
import 'package:mlv_college/Screens/UserHomePage/user_dashboard.dart';
import 'package:mlv_college/Screens/UserHomePage/user_signup.dart';
import 'package:mlv_college/Screens/UserHomePage/ViewUpdates/view_gallery_item.dart';
import 'package:mlv_college/Screens/UserHomePage/ViewUpdates/view_notifications.dart';
import 'package:mlv_college/Screens/UserHomePage/ViewUpdates/view_student_updates.dart';
import 'package:mlv_college/Screens/UserHomePage/ViewUpdates/view_upcoming_events.dart';
import 'package:mlv_college/Screens/MainScreens/login_page.dart';
import 'package:mlv_college/Screens/splash_screen.dart';
import 'package:mlv_college/Screens/AdminHomePage/AddUpdates/add_students_update.dart';
import 'package:mlv_college/Screens/UserHomePage/pdf_view_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MLV College',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/pdf_view') {
          final args = settings.arguments as Map<String, dynamic>;
          final String filePath = args['filePath'] as String;
          final String topic = args['topic'] as String;
          return MaterialPageRoute(
            builder: (context) => PDFViewPage(filePath: filePath, topic: topic),
          );
        } else if (settings.name == '/user_home') {
          final args = settings.arguments as Map<String, dynamic>;
          final String userName = args['userName'] as String;
          return MaterialPageRoute(
            builder: (context) => UserHomePage(userName: userName),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/admin_home': (context) => AdminHomePage(),
        '/signup': (context) => UserSignupPage(),
        '/admin_login': (context) => AdminLoginPage(),
        '/add_students_update': (context) => AddStudentsUpdatePage(),
        '/view_students_updates': (context) => ViewStudentUpdatesPage(),
        '/add_upcoming_event': (context) => AddUpcomingEventPage(),
        '/manage_upcoming_event': (context) => ManageUpcomingEventsPage(),
        '/view_upcoming_events': (context) => ViewUpcomingEventPage(),
        '/add_notification': (context) => AddNotificationPage(),
        '/manage_notification': (context) => ManageNotificationsPage(),
        '/notifications': (context) => ViewNotificationsPage(),
        '/add_newsletter': (context) => AddNewsletterPage(),
        '/manage_newsletter': (context) => ManageNewslettersPage(),
        '/manage_students_update': (context) => ManageStudentUpdatesPage(),
        '/newsletters': (context) => ViewNewsletterPage(),
        '/add_gallery_item': (context) => AddGalleryPage(),
        '/manage_gallery_item': (context) => ManageGalleryPage(),
        '/gallery': (context) => ViewGalleryPage(),
        '/user_home': (context) => UserHomePage(userName: 'userName'), // Example default userName
      },
    );
  }
}