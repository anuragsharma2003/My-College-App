import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ViewGalleryPage extends StatefulWidget {
  @override
  _ViewGalleryPageState createState() => _ViewGalleryPageState();
}

class _ViewGalleryPageState extends State<ViewGalleryPage> {
  int _currentImageIndex = 0;

  void _openPhotoViewGallery(BuildContext context, List<String> imageUrls, int initialIndex, String topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(topic),
            backgroundColor: Colors.blue,
          ),
          body: PhotoViewGallery.builder(
            itemCount: imageUrls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
              );
            },
            scrollPhysics: BouncingScrollPhysics(),
            backgroundDecoration: BoxDecoration(
              color: Colors.black,
            ),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gallery')
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
            return Center(child: Text('No gallery items available'));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final topic = doc['topic'] ?? 'No Topic';
              final description = doc['description'] ?? '';
              final imageUrls = List<String>.from(doc['image_urls'] ?? []);
              final timestamp = (doc['timestamp'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd-MM-yyyy').format(timestamp);

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic
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
                      SizedBox(height: 8), // Reduced gap between topic and description
                      // Description
                      description.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 40,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          description.length > 80
                              ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Description'),
                                    content: SingleChildScrollView(
                                      child: Text(description),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text('Close'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text('See More'),
                            ),
                          )
                              : Container(),
                        ],
                      )
                          : Container(),
                      SizedBox(height: 5), // Reduced gap between description and date
                      // Date
                      Text(
                        'Date: $formattedDate',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8), // Reduced gap between date and slider
                      // Images
                      imageUrls.isNotEmpty
                          ? imageUrls.length > 1
                          ? GestureDetector(
                        onTap: () {
                          int selectedIndex = 0; // Replace this with the correct index when the image is clicked
                          _openPhotoViewGallery(context, imageUrls, selectedIndex, topic);
                        },
                        child: Container(
                          height: 400, // Increased height
                          width: double.infinity, // Full width
                          child: CarouselSlider.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index, realIndex) {
                              final imageUrl = imageUrls[index];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain, // Ensure full image visibility
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) {
                                        return child;
                                      } else {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                    },
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12), // Rounded rectangle shape
                                      ),
                                      child: Text(
                                        '${index + 1}/${imageUrls.length}',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            options: CarouselOptions(
                              autoPlay: false,
                              aspectRatio: 16 / 9,
                              viewportFraction: 1.0,
                              enlargeCenterPage: false,
                              disableCenter: true, // Centering to remove extra space
                              enlargeStrategy: CenterPageEnlargeStrategy.height,
                            ),
                          ),
                        ),
                      )
                          : GestureDetector(
                        onTap: () {
                          int selectedIndex = 0; // Replace this with the correct index when the image is clicked
                          _openPhotoViewGallery(context, imageUrls, selectedIndex, topic);
                        },
                        child: Center(
                          child: Image.network(
                            imageUrls.first,
                            fit: BoxFit.contain, // Ensure full image visibility
                            height: 400, // Increased height
                            width: double.infinity, // Full width
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) {
                                return child;
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          ),
                        ),
                      )
                          : Text('No images available'),
                      SizedBox(height: 10), // Reduced padding at the bottom of the card
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



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:carousel_slider/carousel_slider.dart';
//
// class ViewGalleryPage extends StatefulWidget {
//   @override
//   _ViewGalleryPageState createState() => _ViewGalleryPageState();
// }
//
// class _ViewGalleryPageState extends State<ViewGalleryPage> {
//   int _currentImageIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Gallery'),
//         backgroundColor: Colors.blue,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('gallery')
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No gallery items available'));
//           }
//
//           final documents = snapshot.data!.docs;
//
//           return ListView.builder(
//             itemCount: documents.length,
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final topic = doc['topic'] ?? 'No Topic';
//               final description = doc['description'] ?? '';
//               final imageUrls = List<String>.from(doc['image_urls'] ?? []);
//               final timestamp = (doc['timestamp'] as Timestamp).toDate();
//               final formattedDate = DateFormat('dd-MM-yyyy').format(timestamp);
//
//               return Card(
//                 margin: const EdgeInsets.all(10),
//                 elevation: 5,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Topic
//                       SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: Text(
//                           topic,
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 8), // Reduced gap between topic and description
//                       // Description
//                       description.isNotEmpty
//                           ? Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ConstrainedBox(
//                             constraints: BoxConstraints(
//                               maxHeight: 40,
//                             ),
//                             child: SingleChildScrollView(
//                               scrollDirection: Axis.vertical,
//                               child: Text(
//                                 description,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ),
//                           description.length > 80
//                               ? Align(
//                             alignment: Alignment.centerRight,
//                             child: TextButton(
//                               onPressed: () {
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => AlertDialog(
//                                     title: Text('Description'),
//                                     content: SingleChildScrollView(
//                                       child: Text(description),
//                                     ),
//                                     actions: [
//                                       TextButton(
//                                         child: Text('Close'),
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                               child: Text('See More'),
//                             ),
//                           )
//                               : Container(),
//                         ],
//                       )
//                           : Container(),
//                       SizedBox(height: 5), // Reduced gap between description and date
//                       // Date
//                       Text(
//                         'Date: $formattedDate',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontStyle: FontStyle.italic,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 8), // Reduced gap between date and slider
//                       // Images
//                       imageUrls.isNotEmpty
//                           ? imageUrls.length > 1
//                           ? GestureDetector(
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => Scaffold(
//                                 appBar: AppBar(
//                                   title: Text(topic),
//                                   backgroundColor: Colors.blue,
//                                 ),
//                                 body: PhotoViewGallery.builder(
//                                   itemCount: imageUrls.length,
//                                   builder: (context, index) {
//                                     return PhotoViewGalleryPageOptions(
//                                       imageProvider: NetworkImage(imageUrls[index]),
//                                       minScale: PhotoViewComputedScale.contained,
//                                       maxScale: PhotoViewComputedScale.covered * 2,
//                                       heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
//                                     );
//                                   },
//                                   scrollPhysics: BouncingScrollPhysics(),
//                                   backgroundDecoration: BoxDecoration(
//                                     color: Colors.black,
//                                   ),
//                                   onPageChanged: (index) {
//                                     setState(() {
//                                       _currentImageIndex = index;
//                                     });
//                                   },
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           height: 400, // Increased height
//                           width: double.infinity, // Full width
//                           child: CarouselSlider.builder(
//                             itemCount: imageUrls.length,
//                             itemBuilder: (context, index, realIndex) {
//                               final imageUrl = imageUrls[index];
//                               return Stack(
//                                 fit: StackFit.expand,
//                                 children: [
//                                   Image.network(
//                                     imageUrl,
//                                     fit: BoxFit.contain, // Ensure full image visibility
//                                     loadingBuilder: (context, child, progress) {
//                                       if (progress == null) {
//                                         return child;
//                                       } else {
//                                         return Center(
//                                           child: CircularProgressIndicator(),
//                                         );
//                                       }
//                                     },
//                                   ),
//                                   Positioned(
//                                     right: 10,
//                                     top: 10,
//                                     child: Container(
//                                       padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                                       decoration: BoxDecoration(
//                                         color: Colors.black.withOpacity(0.5),
//                                         borderRadius: BorderRadius.circular(12), // Rounded rectangle shape
//                                       ),
//                                       child: Text(
//                                         '${index + 1}/${imageUrls.length}',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                             options: CarouselOptions(
//                               autoPlay: false,
//                               aspectRatio: 16 / 9,
//                               viewportFraction: 1.0,
//                               enlargeCenterPage: false,
//                               disableCenter: true, // Centering to remove extra space
//                               enlargeStrategy: CenterPageEnlargeStrategy.height,
//                             ),
//                           ),
//                         ),
//                       )
//                           : GestureDetector(
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => Scaffold(
//                                 appBar: AppBar(
//                                   title: Text(topic),
//                                   backgroundColor: Colors.blue,
//                                 ),
//                                 body: Center(
//                                   child: PhotoView(
//                                     imageProvider: NetworkImage(imageUrls.first),
//                                     minScale: PhotoViewComputedScale.contained,
//                                     maxScale: PhotoViewComputedScale.covered * 2,
//                                     heroAttributes: PhotoViewHeroAttributes(tag: imageUrls.first),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                         child: Center(
//                           child: Image.network(
//                             imageUrls.first,
//                             fit: BoxFit.contain, // Ensure full image visibility
//                             height: 400, // Increased height
//                             width: double.infinity, // Full width
//                             loadingBuilder: (context, child, progress) {
//                               if (progress == null) {
//                                 return child;
//                               } else {
//                                 return Center(
//                                   child: CircularProgressIndicator(),
//                                 );
//                               }
//                             },
//                           ),
//                         ),
//                       )
//                           : Text('No images available'),
//                       SizedBox(height: 10), // Reduced padding at the bottom of the card
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }