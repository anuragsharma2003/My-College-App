import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ViewNewsletterPage extends StatefulWidget {
  @override
  _ViewNewsletterPageState createState() => _ViewNewsletterPageState();
}

class _ViewNewsletterPageState extends State<ViewNewsletterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Newsletters'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('newsletters')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No newsletters available'));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final topic = doc['topic'] ?? 'No Topic';
              final fileUrl = doc['file_url'] ?? '';
              final timestamp = (doc['timestamp'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd-MM-yyyy').format(timestamp);

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // Thumbnail and Topic
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        color: Colors.blue.shade50,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            // Thumbnail placeholder
                            Container(
                              width: 50,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: Icon(
                                FontAwesomeIcons.solidFilePdf,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            SizedBox(width: 10),
                            // Topic and Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Button Row
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          fileUrl.isNotEmpty
                              ? ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/pdf_view',
                                arguments: {
                                  'filePath': fileUrl,
                                  'topic': topic,
                                },
                              );
                            },
                            icon: Icon(Icons.picture_as_pdf),
                            label: Text('View Newsletter'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                              : Text(
                            'No file available',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}