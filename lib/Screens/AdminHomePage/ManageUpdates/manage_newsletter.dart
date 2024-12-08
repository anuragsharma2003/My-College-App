import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mlv_college/Screens/UserHomePage/pdf_view_page.dart'; // Import your PDFViewPage

class ManageNewslettersPage extends StatefulWidget {
  @override
  _ManageNewslettersPageState createState() => _ManageNewslettersPageState();
}

class _ManageNewslettersPageState extends State<ManageNewslettersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _newslettersStream;
  bool _isUpdating = false; // Track if updating
  bool _isDeleting = false; // Track if deleting

  @override
  void initState() {
    super.initState();
    _newslettersStream = _firestore
        .collection('newsletters')
        .orderBy('timestamp', descending: true) // Order by timestamp
        .snapshots();
  }

  Future<void> _deleteNewsletter(String docId) async {
    setState(() {
      _isDeleting = true; // Show loader
    });

    try {
      await _firestore.collection('newsletters').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Newsletter deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete newsletter: $e')),
      );
    } finally {
      setState(() {
        _isDeleting = false; // Hide loader
      });
    }
  }

  Future<void> _updateNewsletter(
      String docId, String newTopic, File? newFile) async {
    setState(() {
      _isUpdating = true; // Show loader
    });

    try {
      String? newFileUrl;

      // If a new file is selected, upload it
      if (newFile != null) {
        final fileName = newFile.uri.pathSegments.last;
        final storageRef = FirebaseStorage.instance.ref().child('newsletters/$fileName');
        final uploadTask = storageRef.putFile(newFile);
        final snapshot = await uploadTask;
        newFileUrl = await snapshot.ref.getDownloadURL();
      }

      // Update Firestore document
      await _firestore.collection('newsletters').doc(docId).update({
        'topic': newTopic,
        if (newFileUrl != null) 'file_url': newFileUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Newsletter updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update newsletter: $e')),
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
        title: Text('Delete Newsletter'),
        content: Text('Do you really want to delete this newsletter?'),
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
              _deleteNewsletter(docId); // Proceed to delete the newsletter
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(BuildContext context, String docId, String initialTopic, String initialFileUrl) {
    TextEditingController topicController = TextEditingController(text: initialTopic);
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Newsletter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                decoration: InputDecoration(labelText: 'Topic'),
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
              _updateNewsletter(
                docId,
                topicController.text,
                selectedFile,
              ); // Proceed to update the newsletter
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
        title: Text('Manage Newsletters'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _newslettersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No newsletters found'));
              }

              final newsletters = snapshot.data!.docs;

              return ListView.builder(
                itemCount: newsletters.length,
                itemBuilder: (context, index) {
                  final newsletter = newsletters[index];
                  final docId = newsletter.id;
                  final data = newsletter.data() as Map<String, dynamic>;

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
                          title: Text(topic),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                onPressed: () => _confirmEdit(context, docId, topic, fileUrl),
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
