import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddNewsletterPage extends StatefulWidget {
  @override
  _AddNewsletterPageState createState() => _AddNewsletterPageState();
}

class _AddNewsletterPageState extends State<AddNewsletterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  File? _file;
  bool _isUploading = false;
  String? _fileError;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _fileError = null; // Clear any previous error message
      });
    }
  }

  Future<void> _uploadNewsletter() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_file == null) {
        setState(() {
          _fileError = 'Please select a PDF file.';
        });
        return;
      }

      final topic = _topicController.text;

      setState(() {
        _isUploading = true;
      });

      try {
        String downloadUrl;
        final fileName = _file!.uri.pathSegments.last;
        final storageRef =
        FirebaseStorage.instance.ref().child('newsletters/$fileName');

        // Upload file
        final uploadTask = storageRef.putFile(_file!);
        final snapshot = await uploadTask;

        // Get download URL
        downloadUrl = await snapshot.ref.getDownloadURL();

        // Save data to Firestore with timestamp
        await FirebaseFirestore.instance.collection('newsletters').add({
          'topic': topic,
          'file_url': downloadUrl,
          'timestamp': Timestamp.now(), // Add current timestamp
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Newsletter added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload newsletter: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Newsletter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: 'Topic',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the topic';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(Icons.attach_file),
                  label: Text('Select File'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                if (_file != null) ...[
                  SizedBox(height: 20),
                  Text('Selected file: ${_file!.path.split('/').last}'),
                ],
                if (_fileError != null) ...[
                  SizedBox(height: 10),
                  Text(
                    _fileError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                SizedBox(height: 20),
                _isUploading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _uploadNewsletter,
                  child: Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
