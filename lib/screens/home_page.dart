import 'package:flutter/material.dart';
import '../widgets/EventCard_Widget.dart';

class HomePage extends StatelessWidget { //social media page
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çift Teker"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: const [
          EventCard(),
          EventCard(),
          EventCard(),
        ],
      ),
    );
  }
}