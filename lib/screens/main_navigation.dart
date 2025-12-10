import 'package:cift_teker_front/screens/event_create_page.dart';
import 'package:cift_teker_front/screens/profil_page.dart';
import 'package:cift_teker_front/screens/home_page.dart';
import 'package:cift_teker_front/screens/RideHistory/ride_history_page.dart';
import 'package:cift_teker_front/screens/ride_page.dart';
import 'package:cift_teker_front/screens/shared_route_page.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(), // 0
    EventCreatePage(), // 1
    RidePage(), //2
    SharedRoutePage(), //3
    RideHistoryPage(), //4
    ProfilePage(), //5
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBar _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex == 5 ? 0 : _selectedIndex,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        onItemTapped(index);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: "Ekle"),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: "Harita"),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt),
          label: "Sosyal Medya",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "Sürüş Geçmişi",
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: _selectedIndex < 5
          ? _bottomNav()
          : null, //sadece home, ekleme, paylaşılan, harita, geçmiş sayfası
    );
  }
}
