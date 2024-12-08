import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(8.0),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        children: [
          _buildTile(
            context,
            icon: Icons.notifications,
            title: 'Add Notification',
            routeName: '/add_notification',
            color: Colors.blue,
          ),
          _buildTile(
            context,
            icon: Icons.notifications_active,
            title: 'Manage Notification',
            routeName: '/manage_notification',
            color: Colors.red,
          ),
          _buildTile(
            context,
            icon: Icons.school,
            title: 'Add Students Update',
            routeName: '/add_students_update',
            color: Colors.green,
          ),
          _buildTile(
            context,
            icon: Icons.manage_accounts,
            title: 'Manage Students Update',
            routeName: '/manage_students_update',
            color: Colors.red,
          ),
          _buildTile(
            context,
            icon: Icons.event,
            title: 'Add Upcoming Event',
            routeName: '/add_upcoming_event',
            color: Colors.orange,
          ),
          _buildTile(
            context,
            icon: Icons.event_available,
            title: 'Manage Upcoming Event',
            routeName: '/manage_upcoming_event',
            color: Colors.red,
          ),
          _buildTile(
            context,
            icon: Icons.article,
            title: 'Add Newsletter',
            routeName: '/add_newsletter',
            color: Colors.purple,
          ),
          _buildTile(
            context,
            icon: Icons.description,
            title: 'Manage Newsletter',
            routeName: '/manage_newsletter',
            color: Colors.red,
          ),
          _buildTile(
            context,
            icon: Icons.photo,
            title: 'Add Gallery Item',
            routeName: '/add_gallery_item',
            color: Colors.red,
          ),
          _buildTile(
            context,
            icon: Icons.collections,
            title: 'Manage Gallery Item',
            routeName: '/manage_gallery_item',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required IconData icon,
        required String title,
        required String routeName,
        required Color color}) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48.0),
            SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminHomePage(),
    routes: {
      // '/add_students_update': (context) => AddStudentsUpdatePage(),
      // '/add_newsletter': (context) => AddNewsletterPage(),
      //'/edit_notification': (context) => DeleteNotificationPage(),
      // '/delete_students_update': (context) => DeleteStudentUpdatePage(),
      // '/delete_gallery_item': (context) => DeleteGalleryItemPage(),
      // '/delete_upcoming_event': (context) => DeleteUpcomingEventPage(),
      // '/add_upcoming_event': (context) => AddUpcomingEventPage(),
      // '/add_gallery_item': (context) => AddGalleryItemPage(),
      // Other routes...
    },
  ));
}
