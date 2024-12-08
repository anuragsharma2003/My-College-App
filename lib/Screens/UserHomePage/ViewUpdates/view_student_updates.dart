import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewStudentUpdatesPage extends StatefulWidget {
  @override
  _ViewStudentUpdatesPageState createState() => _ViewStudentUpdatesPageState();
}

class _ViewStudentUpdatesPageState extends State<ViewStudentUpdatesPage> {
  bool _isExpanded = false;
  String _expandedDocId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Updates'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students_updates')
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
            return Center(child: Text('No updates available'));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final topic = doc['topic'] ?? 'No Topic';
              final fileUrl = doc['file_url'] ?? '';
              final description = doc['description'] ?? 'No Description';
              final timestamp = (doc['timestamp'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd-MM-yyyy').format(timestamp);
              final docId = doc.id;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          topic,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: _isExpanded && _expandedDocId == docId
                                    ? double.infinity
                                    : 50, // Adjusted max height for 2 lines
                              ),
                              child: Text(
                                description,
                                overflow: TextOverflow.fade,
                                maxLines: _isExpanded && _expandedDocId == docId
                                    ? null
                                    : 2, // Changed from 3 to 2 lines
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            if (!_isExpanded &&
                                description.length > 100 &&
                                _expandedDocId != docId)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = true;
                                      _expandedDocId = docId;
                                    });
                                  },
                                  child: Text('... See More'),
                                ),
                              )
                            else if (_isExpanded && _expandedDocId == docId)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = false;
                                      _expandedDocId = '';
                                    });
                                  },
                                  child: Text('See Less'),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (fileUrl.isNotEmpty)
                            ElevatedButton(
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
                              child: Text('View File'),
                            )
                          else
                            Text(
                              'No file available',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}