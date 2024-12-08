import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageUpcomingEventsPage extends StatefulWidget {
  @override
  _ManageUpcomingEventsPageState createState() => _ManageUpcomingEventsPageState();
}

class _ManageUpcomingEventsPageState extends State<ManageUpcomingEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _eventsStream;
  bool _isUpdating = false; // Track if updating
  bool _isDeleting = false; // Track if deleting

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestore
        .collection('upcoming_events')
        .orderBy('timestamp', descending: true) // Order by timestamp
        .snapshots();
  }

  Future<void> _deleteEvent(String docId) async {
    setState(() {
      _isDeleting = true; // Show loader
    });

    try {
      await _firestore.collection('upcoming_events').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upcoming event deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete upcoming event: $e')),
      );
    } finally {
      setState(() {
        _isDeleting = false; // Hide loader
      });
    }
  }

  Future<void> _updateEvent(
      String docId, String newTopic, String newDescription, File? newImage) async {
    setState(() {
      _isUpdating = true; // Show loader
    });

    try {
      String? newImageUrl;

      // If a new image is selected, upload it
      if (newImage != null) {
        final fileName = newImage.uri.pathSegments.last;
        final storageRef = FirebaseStorage.instance.ref().child('upcoming_events/$fileName');
        final uploadTask = storageRef.putFile(newImage);
        final snapshot = await uploadTask;
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      // Update Firestore document
      await _firestore.collection('upcoming_events').doc(docId).update({
        'topic': newTopic,
        'description': newDescription,
        if (newImageUrl != null) 'image_url': newImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upcoming event updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update upcoming event: $e')),
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
        title: Text('Delete Upcoming Event'),
        content: Text('Do you really want to delete this upcoming event?'),
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
              _deleteEvent(docId); // Proceed to delete the event
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(BuildContext context, String docId, String initialTopic, String initialDescription, String initialImageUrl) {
    TextEditingController topicController = TextEditingController(text: initialTopic);
    TextEditingController descriptionController = TextEditingController(text: initialDescription);
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Upcoming Event'),
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
                  decoration: InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null && result.files.single.path != null) {
                      setState(() {
                        selectedImage = File(result.files.single.path!);
                      });
                    }
                  },
                  child: Text('Select New Image'),
                ),
                if (selectedImage != null)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      Text('Selected Image:'),
                      SizedBox(height: 10),
                      Image.file(
                        selectedImage!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
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
                _updateEvent(
                  docId,
                  topicController.text,
                  descriptionController.text,
                  selectedImage,
                ); // Proceed to update the event
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Upcoming Events'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _eventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No upcoming events found'));
              }

              final events = snapshot.data!.docs;

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final docId = event.id;
                  final data = event.data() as Map<String, dynamic>;

                  // Extract image URL, topic, description, and timestamp
                  final imageUrl = data['image_url'] ?? '';
                  final topic = data['topic'] ?? 'No Topic';
                  final description = data['description'] ?? 'No Description';
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
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty) Text(description),
                              if (imageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Image.network(imageUrl, height: 200, fit: BoxFit.cover),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _confirmEdit(context, docId, topic, description, imageUrl),
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
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class ManageUpcomingEventsPage extends StatefulWidget {
//   @override
//   _ManageUpcomingEventsPageState createState() => _ManageUpcomingEventsPageState();
// }
//
// class _ManageUpcomingEventsPageState extends State<ManageUpcomingEventsPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late Stream<QuerySnapshot> _eventsStream;
//   bool _isUpdating = false; // Track if updating
//   bool _isDeleting = false; // Track if deleting
//
//   @override
//   void initState() {
//     super.initState();
//     _eventsStream = _firestore
//         .collection('upcoming_events')
//         .orderBy('timestamp', descending: true) // Order by timestamp
//         .snapshots();
//   }
//
//   Future<void> _deleteEvent(String docId) async {
//     setState(() {
//       _isDeleting = true; // Show loader
//     });
//
//     try {
//       await _firestore.collection('upcoming_events').doc(docId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upcoming event deleted successfully')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to delete upcoming event: $e')),
//       );
//     } finally {
//       setState(() {
//         _isDeleting = false; // Hide loader
//       });
//     }
//   }
//
//   Future<void> _updateEvent(
//       String docId, String newTopic, String newDescription, File? newImage) async {
//     setState(() {
//       _isUpdating = true; // Show loader
//     });
//
//     try {
//       String? newImageUrl;
//
//       // If a new image is selected, upload it
//       if (newImage != null) {
//         final fileName = newImage.uri.pathSegments.last;
//         final storageRef = FirebaseStorage.instance.ref().child('upcoming_events/$fileName');
//         final uploadTask = storageRef.putFile(newImage);
//         final snapshot = await uploadTask;
//         newImageUrl = await snapshot.ref.getDownloadURL();
//       }
//
//       // Update Firestore document
//       await _firestore.collection('upcoming_events').doc(docId).update({
//         'topic': newTopic,
//         'description': newDescription,
//         if (newImageUrl != null) 'image_url': newImageUrl,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upcoming event updated successfully')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update upcoming event: $e')),
//       );
//     } finally {
//       setState(() {
//         _isUpdating = false; // Hide loader
//       });
//     }
//   }
//
//   void _confirmDelete(BuildContext context, String docId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Delete Upcoming Event'),
//         content: Text('Do you really want to delete this upcoming event?'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Dismiss the dialog
//             },
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Dismiss the dialog
//               _deleteEvent(docId); // Proceed to delete the event
//             },
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _confirmEdit(BuildContext context, String docId, String initialTopic, String initialDescription, String initialImageUrl) {
//     TextEditingController topicController = TextEditingController(text: initialTopic);
//     TextEditingController descriptionController = TextEditingController(text: initialDescription);
//     File? selectedImage;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Edit Upcoming Event'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: topicController,
//                 decoration: InputDecoration(labelText: 'Topic'),
//               ),
//               TextField(
//                 controller: descriptionController,
//                 decoration: InputDecoration(labelText: 'Description (Optional)'),
//                 maxLines: 3,
//                 keyboardType: TextInputType.multiline,
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   final result = await FilePicker.platform.pickFiles(
//                     type: FileType.image,
//                   );
//                   if (result != null && result.files.single.path != null) {
//                     selectedImage = File(result.files.single.path!);
//                   }
//                 },
//                 child: Text('Select New Image'),
//               ),
//               if (selectedImage != null) Text('Image selected: ${selectedImage!.path}'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Dismiss the dialog
//             },
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Dismiss the dialog
//               _updateEvent(
//                 docId,
//                 topicController.text,
//                 descriptionController.text,
//                 selectedImage,
//               ); // Proceed to update the event
//             },
//             child: Text('Confirm'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Manage Upcoming Events'),
//       ),
//       body: Stack(
//         children: [
//           StreamBuilder<QuerySnapshot>(
//             stream: _eventsStream,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }
//
//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return Center(child: Text('No upcoming events found'));
//               }
//
//               final events = snapshot.data!.docs;
//
//               return ListView.builder(
//                 itemCount: events.length,
//                 itemBuilder: (context, index) {
//                   final event = events[index];
//                   final docId = event.id;
//                   final data = event.data() as Map<String, dynamic>;
//
//                   // Extract image URL, topic, description, and timestamp
//                   final imageUrl = data['image_url'] ?? '';
//                   final topic = data['topic'] ?? 'No Topic';
//                   final description = data['description'] ?? 'No Description';
//                   final timestamp = data['timestamp'] as Timestamp;
//                   final date = DateFormat.yMMMd().format(timestamp.toDate());
//
//                   return Card(
//                     margin: EdgeInsets.all(8.0),
//                     child: Stack(
//                       children: [
//                         ListTile(
//                           contentPadding: EdgeInsets.all(16.0),
//                           title: Text(
//                             topic,
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               if (description.isNotEmpty) Text(description),
//                               if (imageUrl.isNotEmpty)
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                                   child: Image.network(imageUrl, height: 200, fit: BoxFit.cover),
//                                 ),
//                             ],
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 icon: Icon(Icons.edit, color: Colors.orange),
//                                 onPressed: () => _confirmEdit(context, docId, topic, description, imageUrl),
//                               ),
//                               IconButton(
//                                 icon: Icon(Icons.delete, color: Colors.red),
//                                 onPressed: () => _confirmDelete(context, docId),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 8.0,
//                           right: 16.0,
//                           child: Text(
//                             date,
//                             style: TextStyle(fontSize: 14, color: Colors.grey),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//           if (_isUpdating || _isDeleting)
//             Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
// }
