import 'package:flutter/material.dart';
import 'package:fundorex/service/app_string_service.dart';
import 'package:fundorex/service/bottom_nav_service.dart';
import 'package:fundorex/view/events/all_events_page.dart';
import 'package:fundorex/view/home/components/bottom_nav.dart';
import 'package:fundorex/view/home/homepage.dart';
import 'package:fundorex/view/menu/menu_page.dart';
import 'package:fundorex/view/profile/profile_page.dart';
import 'package:provider/provider.dart';

import '../utils/others_helper.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<LandingPage> {
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    // runAtStart(context);
  }

  onTabTapped(int index) {
    Provider.of<BottomNavService>(context, listen: false)
        .setCurrentIndex(index);
    setState(() {
      _currentIndex = index;
    });
  }

  int _currentIndex = 0;

  //Bottom nav pages
  final List<Widget> _children = [
    const Homepage(),
    const AllEventsPage(),
    const MenuPage(),
    const ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStringService>(
      builder: (context, ln, child) => Consumer<BottomNavService>(
        builder: (context, provider, child) => Scaffold(
          backgroundColor: Colors.white,
          body: WillPopScope(
              onWillPop: () {
                DateTime now = DateTime.now();
                if (currentBackPressTime == null ||
                    now.difference(currentBackPressTime!) >
                        const Duration(seconds: 2)) {
                  currentBackPressTime = now;
                  OthersHelper().showToast(
                      ln.getString("Press again to exit"), Colors.black);
                  return Future.value(false);
                }
                return Future.value(true);
              },
              child: _children[provider.currentIndex]),
          bottomNavigationBar: BottomNav(
            currentIndex: provider.currentIndex,
            onTabTapped: onTabTapped,
          ),
        ),
      ),
    );
  }
}
