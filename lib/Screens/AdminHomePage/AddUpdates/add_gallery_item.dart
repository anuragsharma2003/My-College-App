import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddGalleryPage extends StatefulWidget {
  @override
  _AddGalleryPageState createState() => _AddGalleryPageState();
}

class _AddGalleryPageState extends State<AddGalleryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _images = [];
  bool _isUploading = false;
  int _uploadedCount = 0; // Track number of uploaded images
  int _totalImages = 0; // Total number of images to upload

  Future<void> _pickImages() async {
    final results = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (results != null) {
      setState(() {
        _images = results.paths.map((path) => File(path!)).toList();
        _uploadedCount = 0; // Reset uploaded count when picking new images
        _totalImages = _images.length; // Set total number of images
      });
    }
  }

  void _removeImage(File image) {
    setState(() {
      _images.remove(image);
      _totalImages = _images.length; // Update total image count
      if (_uploadedCount > _totalImages) {
        _uploadedCount = _totalImages; // Adjust uploaded count if necessary
      }
    });
  }

  Future<void> _uploadGalleryItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      final topic = _topicController.text;
      final description = _descriptionController.text;
      final images = _images;

      if (images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadedCount = 0; // Reset uploaded count
      });

      try {
        List<String> downloadUrls = [];

        for (int i = 0; i < _totalImages; i++) {
          File image = images[i];
          final fileName = image.uri.pathSegments.last;
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('gallery/$fileName');

          // Upload file
          final uploadTask = storageRef.putFile(image);

          // Track progress and update uploaded count
          uploadTask.snapshotEvents.listen((snapshot) {
            if (snapshot.state == TaskState.success) {
              setState(() {
                _uploadedCount++;
              });
            }
          });

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          downloadUrls.add(downloadUrl);
        }

        // Save data to Firestore with timestamp
        await FirebaseFirestore.instance.collection('gallery').add({
          'topic': topic,
          'description': description,
          'image_urls': downloadUrls,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery item added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload gallery item: $e')),
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
    double progress = _totalImages > 0 ? _uploadedCount / _totalImages : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Gallery Item'),
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
                  onPressed: _pickImages,
                  icon: Icon(Icons.image),
                  label: Text('Select Images'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                if (_images.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _images.asMap().entries.map((entry) {
                      int index = entry.key;
                      File image = entry.value;
                      return Stack(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.file(
                              image,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _removeImage(image),
                              child: Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                ],
                SizedBox(height: 20),
                _isUploading
                    ? Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      child: Stack(
                        children: [
                          Center(
                            child: CircularProgressIndicator(
                              value: progress,
                              color: Colors.white,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${_uploadedCount}/${_totalImages}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                )
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