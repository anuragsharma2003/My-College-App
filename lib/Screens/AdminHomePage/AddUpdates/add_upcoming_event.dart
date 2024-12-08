import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddUpcomingEventPage extends StatefulWidget {
  @override
  _AddUpcomingEventPageState createState() => _AddUpcomingEventPageState();
}

class _AddUpcomingEventPageState extends State<AddUpcomingEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadGalleryItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      final topic = _topicController.text;
      final description = _descriptionController.text;
      final image = _selectedImage;

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        final fileName = image.uri.pathSegments.last;
        final storageRef = FirebaseStorage.instance.ref().child('upcoming_events/$fileName');

        // Upload file
        final uploadTask = storageRef.putFile(image);
        final snapshot = await uploadTask;

        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Save data to Firestore with timestamp
        await FirebaseFirestore.instance.collection('upcoming_events').add({
          'topic': topic,
          'description': description,
          'image_url': downloadUrl,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upcoming event added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload upcoming event: $e')),
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
        title: Text('Add Upcoming Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    labelText: 'Description (Optional)',
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Select Image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                if (_selectedImage != null) ...[
                  SizedBox(height: 20),
                  Center(
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                SizedBox(height: 20),
                _isUploading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _uploadGalleryItem,
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