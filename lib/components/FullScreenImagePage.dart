import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final String? imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: 'profile_image_hero',
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: imageUrl != null
                ? Image.network(imageUrl!)
                : Image.asset("assets/ciftTeker.png"),
          ),
        ),
      ),
    );
  }
}
