import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hfn_work/auth_screen/welcome.dart';
import 'package:hfn_work/main_screen/user_screen/video/play_video_bedtime_screen.dart';
import 'package:hfn_work/main_screen/user_screen/video/play_video_morning_screen.dart';
import 'package:intl/intl.dart';
import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class home_screen extends StatefulWidget {
  @override
  _home_screen createState() => _home_screen();
}

class _home_screen extends State<home_screen> with RouteAware {
  int? doneWeek;
  int? doneDay;
  bool showLoader = false;
  bool check = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    updateDayAndWeek();
  }

  Future<void> getUserData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      check = pref.get('user_id') != null;
    });
    if (check) {
      updateDayAndWeek();
    }
  }

  int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return (t.difference(f).inHours / 24).round();
  }

  Future<void> updateDayAndWeek() async {
    final pref = await SharedPreferences.getInstance();
    final userId = pref.getString('user_id');
    if (userId == null) {
      setState(() {
        showLoader = false;
      });
      return;
    }

    final userQuery = FirebaseFirestore.instance
        .collection('user')
        .where('id', isEqualTo: userId);

    userQuery.get().then((snap) {
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startDate = DateTime.parse(data['start_date'] as String);
        final totalDays = daysBetween(startDate, DateTime.now());
        setState(() {
          doneWeek = totalDays ~/ 7;
          doneDay = totalDays % 7;
          showLoader = false;
        });
      }
    }).catchError((_) {
      setState(() {
        showLoader = false;
      });
    });
  }

  Future<void> _logout() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => welcome()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning!'
        : hour < 18
        ? 'Good Afternoon!'
        : 'Good Evening!';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Start your day…',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFF333333),
                    width: 2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => play_video_morning_screen(
                          title: 'Morning Practice',
                          url: 'assets/audio/morning.mp3',
                          week: doneWeek ?? 0,
                          day: doneDay ?? 0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Morning Practice',
                                style: TextStyle(
                                  fontFamily: 'WorkSans',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Color(0xFF666666),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '10:02',
                                    style: TextStyle(color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/waterfall.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'End your day…',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFF333333),
                    width: 2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => play_video_bedtime_screen(
                          title: 'Bedtime Practice',
                          url: 'assets/audio/bedtime.mp3',
                          week: doneWeek ?? 0,
                          day: doneDay ?? 0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Bedtime Practice',
                                style: TextStyle(
                                  fontFamily: 'WorkSans',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Color(0xFF666666),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '10:02',
                                    style: TextStyle(color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/forest.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
