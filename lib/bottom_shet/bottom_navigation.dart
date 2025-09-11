import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hfn_work/bottom_shet/bottom_tabs.dart';
import 'package:hfn_work/utils/styles.dart';
import 'package:hfn_work/auth_screen/welcome.dart';
import 'package:shared_preferences/shared_preferences.dart';

class bottom_navigation extends StatefulWidget {
  @override
  _bottom_navigation createState() => _bottom_navigation();
}

class _bottom_navigation extends State<bottom_navigation> {
  int currentIndex = 0;

  void _onItemTapped(int index) async {
    // Check if user is a guest trying to access profile/settings (index 1)
    if (index == 1 && !check) {
      _showGuestLoginDialog();
      return;
    }
    
    setState(() {
      currentIndex = index;
      print('_selectedIndex');
      print(currentIndex);
    });
  }

  void _showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F4F5),
          title: const Text(
            'Login Required',
            style: TextStyle(
              fontFamily: 'WorkSans',
              color: Color(0xFF485370),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'To access your profile and settings, please login or create an account.',
            style: TextStyle(
              fontFamily: 'WorkSans',
              color: Color(0xFF485370),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  color: Color(0xFF0F75BC),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => welcome()),
                  (route) => false,
                );
              },
              child: const Text(
                'Go to Login',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  color: Color(0xFF0F75BC),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    print("Dispose");
    super.dispose();
  }

  bool check = false;

  getUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      check = pref.get('user_id') != null ? true : false;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final greyColor = const Color(0xFFF6F4F5);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          for (final tabItem in TabNavigationItem.items) tabItem.page!,
        ],
      ),

      bottomNavigationBar: Container(
        height: 100,               // <–– make the bar taller
        color: greyColor,         // <–– your desired background
        child: BottomNavigationBar(
          backgroundColor: greyColor,  // ensure the bar itself is the same color
          currentIndex: currentIndex,
          onTap: _onItemTapped,

          type: BottomNavigationBarType.fixed,
          iconSize: 60,                // <–– bump the icon size

          selectedIconTheme: IconThemeData(
            size: 40,                   // <–– selected icon even larger
            color: appColor,
          ),
          unselectedIconTheme: IconThemeData(
            size: 40,                   // <–– unselected a bit smaller
            color: Colors.grey,
          ),

          selectedItemColor: appColor,
          unselectedItemColor: Colors.grey,

          selectedFontSize: 0,         // hide labels (you had empty strings)
          unselectedFontSize: 0,

          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                currentIndex == 0
                    ? 'assets/icons/home_selected.png'
                    : 'assets/icons/home_unselected.png',
                width: 45,
                height: 45,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                currentIndex == 1
                    ? 'assets/icons/settings_selected.png'
                    : 'assets/icons/settings_unselected.png',
                width: 60,
                height: 60,
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
  }
