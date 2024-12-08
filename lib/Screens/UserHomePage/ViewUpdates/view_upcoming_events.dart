import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class ViewUpcomingEventPage extends StatefulWidget {
  @override
  _ViewUpcomingEventPageState createState() => _ViewUpcomingEventPageState();
}

class _ViewUpcomingEventPageState extends State<ViewUpcomingEventPage> {
  // Maintain the state for expanded description
  final Map<String, bool> _expandedDescriptions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upcoming Events'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('upcoming_events')
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
            return Center(child: Text('No upcoming events available'));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final topic = doc['topic'] ?? 'No Topic';
              final description = doc['description'] ?? '';
              final imageUrl = doc['image_url'] ?? '';
              final timestamp = (doc['timestamp'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd-MM-yyyy').format(timestamp);

              final isExpanded = _expandedDescriptions[doc.id] ?? false;

              return Card(
                margin: const EdgeInsets.all(12), // Increased margin for larger cards
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(24.0), // Increased padding for content
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          topic,
                          style: TextStyle(
                            fontSize: 20, // Unchanged
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Description
                      description.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: isExpanded ? double.infinity : 50, // Expand height if expanded
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(
                                description,
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (description.length > 100 && !isExpanded) // Adjust the length based on your needs
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _expandedDescriptions[doc.id] = true; // Expand description
                                  });
                                },
                                child: Text('See More'),
                              ),
                            )
                          else if (isExpanded) // Show 'See Less' if expanded
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _expandedDescriptions[doc.id] = false; // Collapse description
                                  });
                                },
                                child: Text('See Less'),
                              ),
                            ),
                        ],
                      )
                          : Container(),
                      SizedBox(height: 5), // Reduced space before image
                      // Date
                      Text(
                        'Date: $formattedDate',
                        style: TextStyle(
                          fontSize: 14, // Unchanged
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20), // Increased space before image
                      // Image
                      imageUrl.isNotEmpty
                          ? GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text(topic),
                                  backgroundColor: Colors.blue,
                                ),
                                body: Center(
                                  child: PhotoView(
                                    imageProvider:
                                    NetworkImage(imageUrl),
                                    minScale:
                                    PhotoViewComputedScale.contained,
                                    maxScale:
                                    PhotoViewComputedScale.covered *
                                        2,
                                    heroAttributes:
                                    PhotoViewHeroAttributes(
                                        tag: imageUrl),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            height: 450, // Increased image height
                            width: double.infinity,
                          ),
                        ),
                      )
                          : Text('No image available'),
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