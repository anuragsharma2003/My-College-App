import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mlv_college/Screens/UserHomePage/pdf_view_page.dart'; // Import your PDFViewPage

class ManageNotificationsPage extends StatefulWidget {
  @override
  _ManageNotificationsPageState createState() => _ManageNotificationsPageState();
}

class _ManageNotificationsPageState extends State<ManageNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _notificationsStream;
  bool _isUpdating = false; // Track if updating
  bool _isDeleting = false; // Track if deleting

  @override
  void initState() {
    super.initState();
    _notificationsStream = _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true) // Order by timestamp
        .snapshots();
  }

  Future<void> _deleteNotification(String docId) async {
    setState(() {
      _isDeleting = true; // Show loader
    });

    try {
      await _firestore.collection('notifications').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    } finally {
      setState(() {
        _isDeleting = false; // Hide loader
      });
    }
  }

  Future<void> _updateNotification(
      String docId, String newTopic, String newDescription, File? newFile) async {
    setState(() {
      _isUpdating = true; // Show loader
    });

    try {
      String? newFileUrl;

      // If a new file is selected, upload it
      if (newFile != null) {
        final fileName = newFile.uri.pathSegments.last;
        final storageRef = FirebaseStorage.instance.ref().child('notifications/$fileName');
        final uploadTask = storageRef.putFile(newFile);
        final snapshot = await uploadTask;
        newFileUrl = await snapshot.ref.getDownloadURL();
      }

      // Update Firestore document
      await _firestore.collection('notifications').doc(docId).update({
        'topic': newTopic,
        'description': newDescription,
        if (newFileUrl != null) 'file_url': newFileUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false; // Hide loader
      });
    }
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notification'),
        content: Text('Do you really want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
              _deleteNotification(docId); // Proceed to delete the notification
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(BuildContext context, String docId, String initialTopic,
      String initialDescription, String initialFileUrl) {
    TextEditingController topicController = TextEditingController(text: initialTopic);
    TextEditingController descriptionController = TextEditingController(text: initialDescription);
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                decoration: InputDecoration(labelText: 'Topic'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.single.path != null) {
                    selectedFile = File(result.files.single.path!);
                  }
                },
                child: Text('Select New File'),
              ),
              if (selectedFile != null) Text('File selected: ${selectedFile!.path}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
              _updateNotification(
                docId,
                topicController.text,
                descriptionController.text,
                selectedFile,
              ); // Proceed to update the notification
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _viewFile(BuildContext context, String url, String topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewPage(filePath: url, topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Notifications'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No notifications found'));
              }

              final notifications = snapshot.data!.docs;

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final docId = notification.id;
                  final data = notification.data() as Map<String, dynamic>;

                  // Extract file URL, topic, and timestamp
                  final fileUrl = data['file_url'] ?? '';
                  final topic = data['topic'] ?? 'No Topic';
                  final timestamp = data['timestamp'] as Timestamp;
                  final date = DateFormat.yMMMd().format(timestamp.toDate());

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text(
                            topic,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['description'] ?? 'No Description'),
                              SizedBox(height: 8.0),
                              if (fileUrl.isNotEmpty)
                                TextButton(
                                  onPressed: () => _viewFile(context, fileUrl, topic),
                                  child: Text('View File'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _confirmEdit(context, docId, topic, data['description'] ?? '', fileUrl),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, docId),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 8.0,
                          right: 16.0,
                          child: Text(
                            date,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_isUpdating || _isDeleting)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}