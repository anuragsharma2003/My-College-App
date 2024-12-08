import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_gallery_page.dart';

class ManageGalleryPage extends StatefulWidget {
  @override
  _ManageGalleryPageState createState() => _ManageGalleryPageState();
}

class _ManageGalleryPageState extends State<ManageGalleryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _galleryStream;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _galleryStream = _firestore.collection('gallery').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _deleteGalleryItem(String docId) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _firestore.collection('gallery').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery item deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gallery item: $e')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Gallery Item'),
        content: Text('Do you really want to delete this gallery item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteGalleryItem(docId);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(BuildContext context, String docId, String initialTopic, String initialDescription, List<String> initialImageUrls) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditGalleryPage(
          docId: docId,
          initialTopic: initialTopic,
          initialDescription: initialDescription,
          initialImageUrls: initialImageUrls,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Gallery Items'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _galleryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No gallery items found'));
              }

              final galleryItems = snapshot.data!.docs;

              return ListView.builder(
                itemCount: galleryItems.length,
                itemBuilder: (context, index) {
                  final item = galleryItems[index];
                  final docId = item.id;
                  final data = item.data() as Map<String, dynamic>;
                  final imageUrls = List<String>.from(data['image_urls'] ?? []);
                  final topic = data['topic'] ?? 'No Topic';
                  final description = data['description'] ?? 'No Description';
                  final timestamp = data['timestamp'] as Timestamp;
                  final date = DateFormat.yMMMd().format(timestamp.toDate());

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  topic,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Container(
                                height: 40.0,
                                child: SingleChildScrollView(
                                  child: Text(
                                    description,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.0),
                              if (imageUrls.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4.0,
                                    mainAxisSpacing: 4.0,
                                  ),
                                  itemCount: imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.network(
                                            imageUrls[index],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.error);
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
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
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Spacer(flex: 6), // Pushes the buttons slightly to the left
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _confirmEdit(context, docId, topic, description, imageUrls),
                            ),
                            Spacer(), // Adds space between the buttons
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, docId),
                            ),
                            Spacer(flex: 3), // Pushes the date to the right side
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                date,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_isDeleting)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}