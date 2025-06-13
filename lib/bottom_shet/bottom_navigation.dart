import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hfn_work/bottom_shet/bottom_tabs.dart';
import 'package:hfn_work/utils/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class bottom_navigation extends StatefulWidget {
  @override
  _bottom_navigation createState() => _bottom_navigation();
}

class _bottom_navigation extends State<bottom_navigation> {
  int currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
      print('_selectedIndex');
      print(currentIndex);
    });
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
          onTap: check
              ? _onItemTapped
              : (i) => Fluttertoast.showToast(
            msg: 'Do login first',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: greyColor,
            textColor: Colors.white,
          ),

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
                width: 60,
                height: 60,
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
