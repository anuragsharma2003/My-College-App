import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddStudentsUpdatePage extends StatefulWidget {
  @override
  _AddStudentsUpdatePageState createState() => _AddStudentsUpdatePageState();
}

class _AddStudentsUpdatePageState extends State<AddStudentsUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _file;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadStudentsUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      final topic = _topicController.text;
      final description = _descriptionController.text;
      final file = _file;

      setState(() {
        _isUploading = true;
      });

      try {
        String? downloadUrl;
        if (file != null) {
          final fileName = file.uri.pathSegments.last;
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('students_updates/$fileName');

          // Upload file
          final uploadTask = storageRef.putFile(file);
          final snapshot = await uploadTask;

          // Get download URL
          downloadUrl = await snapshot.ref.getDownloadURL();
        }

        // Save data to Firestore with timestamp
        await FirebaseFirestore.instance.collection('students_updates').add({
          'topic': topic,
          'description': description,
          'file_url': downloadUrl ?? '', // Save an empty string if no file
          'timestamp': Timestamp.now(), // Add current timestamp
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload update: $e')),
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
        title: Text('Add Students Update'),
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
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
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
                SizedBox(height: 20),
                if (_file != null) ...[
                  Text('Selected file: ${_file!.path.split('/').last}'),
                ],
                SizedBox(height: 20),
                _isUploading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _uploadStudentsUpdate,
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