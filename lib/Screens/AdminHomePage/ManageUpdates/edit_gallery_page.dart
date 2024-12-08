import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class EditGalleryPage extends StatefulWidget {
  final String docId;
  final String initialTopic;
  final String initialDescription;
  final List<String> initialImageUrls;

  EditGalleryPage({
    required this.docId,
    required this.initialTopic,
    required this.initialDescription,
    required this.initialImageUrls,
  });

  @override
  _EditGalleryPageState createState() => _EditGalleryPageState();
}

class _EditGalleryPageState extends State<EditGalleryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _topicController;
  late TextEditingController _descriptionController;
  List<File> _selectedImages = [];
  List<String> _imageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.initialTopic);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _imageUrls = widget.initialImageUrls;
  }

  Future<void> _selectNewImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImages = result.files.map((file) => File(file.path!)).toList();
      });
    }
  }

  void _removeImage(String imageUrl) {
    setState(() {
      _imageUrls.remove(imageUrl);
    });
  }

  Future<void> _updateGalleryItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Start loading
      });

      List<String> newImageUrls = List.from(_imageUrls);

      if (_selectedImages.isNotEmpty) {
        try {
          for (File image in _selectedImages) {
            final fileName = image.uri.pathSegments.last;
            final storageRef = FirebaseStorage.instance.ref().child('gallery/$fileName');
            final uploadTask = storageRef.putFile(image);

            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();
            newImageUrls.add(downloadUrl);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload images: $e')),
          );
          setState(() {
            _isLoading = false; // Stop loading
          });
          return;
        }
      }

      try {
        await FirebaseFirestore.instance.collection('gallery').doc(widget.docId).update({
          'topic': _topicController.text,
          'description': _descriptionController.text,
          'image_urls': newImageUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery item updated successfully')),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update gallery item: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Gallery Item'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    onPressed: _selectNewImages,
                    icon: Icon(Icons.image),
                    label: Text('Select New Images'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  if (_imageUrls.isNotEmpty || _selectedImages.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text('Current Images:', style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  _imageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.error);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  padding: EdgeInsets.all(4.0),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(_imageUrls[index]),
                                  child: Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Selected Images:', style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                padding: EdgeInsets.all(4.0),
                                child: Text(
                                  '${widget.initialImageUrls.length + index + 1}',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Return to previous screen without saving
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _updateGalleryItem,
                        child: Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
