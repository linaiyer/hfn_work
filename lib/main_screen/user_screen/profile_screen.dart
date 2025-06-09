import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/main.dart';
import 'package:hfn_work/main_screen/terms_of_use.dart';
import 'package:hfn_work/main_screen/user_screen/additional_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class profile_screen extends StatefulWidget {
  @override
  _profile_screen createState() => _profile_screen();
}

class _profile_screen extends State<profile_screen> with RouteAware {
  Map<String, dynamic>? profileData;  // now holds a single doc’s data
  bool check = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    getUserData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> getUserData() async {
    final pref = await SharedPreferences.getInstance();
    final uid = pref.getString('user_id');
    setState(() {
      check = uid != null;
    });
    if (uid != null) {
      await getUserProfile(uid);
    }
  }

  Future<void> getUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        profileData = doc.data();
      });
    }
  }

  Future<void> _launchURL() async {
    const url = 'https://www.heartfulnessinstitute.org/';
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true);
    }
  }

  void logout() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => login()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = profileData?['name'] as String?;
    final userName    = profileData?['userName'] as String?;
    final titleText = displayName?.isNotEmpty == true
        ? displayName!
        : (userName ?? '');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
            left: 15, right: 15, top: 30, bottom: 15),
        child: Column(
          children: <Widget>[
            const Text(
              'Settings',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Color(0xff744EC3),
                fontSize: 40,
                fontFamily: 'GoudyBookletterRegular',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 15),
                children: <Widget>[
                  // avatar
                  Center(
                    child: Image.asset(
                      'assets/images/profile_avater.png',
                      height: 180,
                      width: 180,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // name or username
                  if (profileData != null)
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xff485370),
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Anaheim',
                      ),
                    ),

                  const SizedBox(height: 20),

                  // log out button
                  Card(
                    color: const Color(0xffF8EEF9),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32.0),
                      onTap: logout,
                      child: Row(
                        children: <Widget>[
                          const Expanded(
                            child: SizedBox(
                              height: 60,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 20, top: 10, bottom: 10),
                                child: Text(
                                  'Log out',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 30,
                                      fontFamily: 'Anaheim'),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Color(0xffB993BC),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 15, right: 15),
                            child: Image.asset(
                              'assets/icons/next_arrow.png',
                              height: 35,
                              width: 35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Additional Resources
                  Card(
                    color: const Color(0xffF8EEF9),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32.0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AdditionalResources()),
                        );
                      },
                      child: Row(
                        children: const <Widget>[
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 20, top: 10, bottom: 10),
                                child: Text(
                                  'Additional Resources',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 26,
                                      fontFamily: 'Anaheim'),
                                ),
                              ),
                            ),
                          ),
                          _DividerIcon(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms and Conditions
                  Card(
                    color: const Color(0xffF8EEF9),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32.0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TermsOfUse()),
                        );
                      },
                      child: Row(
                        children: const <Widget>[
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 20, top: 10, bottom: 10),
                                child: Text(
                                  'Terms and Conditions',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 26,
                                      fontFamily: 'Anaheim'),
                                ),
                              ),
                            ),
                          ),
                          _DividerIcon(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// small helper for your row dividers
class _DividerIcon extends StatelessWidget {
  const _DividerIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 50,
    color: const Color(0xffB993BC),
  );
}
