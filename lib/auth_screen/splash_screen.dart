import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hfn_work/auth_screen/welcome.dart';
import 'package:hfn_work/bottom_shet/bottom_navigation.dart';
import 'package:hfn_work/main.dart';

class splash_screen extends StatefulWidget {
  @override
  _splash_screen createState() => _splash_screen();
}

class _splash_screen extends State<splash_screen> with WidgetsBindingObserver {
  @override
  void initState() {
    // LocalNotification().requestPermissions();
    // LocalNotification().configureDidReceiveLocalNotificationSubject(context);
    // LocalNotification().configureSelectNotificationSubject();
    startTimer();
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("DidChangeDependencies");
  }

  @override
  void setState(fn) {
    print("SetState");
    super.setState(fn);
  }

  @override
  void deactivate() {
    print("Deactivate");
    super.deactivate();
  }

  @override
  void dispose() {
    print("Dispose");
    super.dispose();
    selectNotificationSubject.close();
    // didReceiveLocalNotificationSubject.close();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        print('appLifeCycleState inactive');
        break;
      case AppLifecycleState.resumed:
        print('appLifeCycleState resumed');
        break;
      case AppLifecycleState.paused:
        print('appLifeCycleState paused');
        break;
      case AppLifecycleState.detached:
        print('appLifeCycleState detached');
        break;
    }
  }

  void startTimer() async {
    await Future.delayed(const Duration(seconds: 3));
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => loggedIn ? bottom_navigation() : welcome(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F4F5),
      body: Center(
        child: Image.asset('assets/images/login_image.png'),
      ),
    );
  }
}
