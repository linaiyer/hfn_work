// login.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:hfn_work/bottom_shet/bottom_navigation.dart';
import 'package:hfn_work/main_screen/admin_screen/admin_home_screen.dart';
import 'package:hfn_work/main_screen/super_admin_screen/super_admin_home_screen.dart';
import 'package:hfn_work/notification/push_notification_handler.dart';

class login extends StatefulWidget {
  @override
  _login createState() => _login();
}

class _login extends State<login> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKeyLogin = GlobalKey<FormState>();
  bool showLoader = false;

  Future<void> userAccess() async {
    if (!formKeyLogin.currentState!.validate()) return;
    formKeyLogin.currentState!.save();

    setState(() => showLoader = true);

    final username = userNameController.text.trim();
    final password = passwordController.text.trim();

    try {
      final query = await FirebaseFirestore.instance
          .collection('user')
          .where('userName', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isEmpty) {
        Fluttertoast.showToast(msg: 'Login credentials not match');
        return;
      }

      // ← Grab the first matching document
      final docSnap = query.docs.first;
      final data = docSnap.data() as Map<String, dynamic>;

      // ← Use the Firestore document ID, not a possibly-missing field
      final id       = docSnap.id;
      final userType = (data['user_type']  as String?) ?? '0';
      final start    = (data['start_date'] as String?) ?? '';

      // persist locally
      final pref = await SharedPreferences.getInstance();
      await pref.setString('user_id',   id);
      await pref.setString('user_type', userType);

      // update start_date if it was empty
      if (userType == '0' && start.isEmpty) {
        await docSnap.reference.update({
          'start_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });
      }

      LocalNotification().showDailyAtTime();

      // navigate
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => bottom_navigation()),
            (route) => false,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error logging in: $e');
    } finally {
      if (mounted) setState(() => showLoader = false);
    }
  }


  Future<void> _handleGoogleSignIn() async {
    setState(() => showLoader = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) {
        Fluttertoast.showToast(msg: 'Google sign-in failed: no user');
        return;
      }

      final email = user.email;
      if (email == null) {
        Fluttertoast.showToast(msg: 'Google account has no email');
        return;
      }

      final pref = await SharedPreferences.getInstance();
      final usersRef = FirebaseFirestore.instance.collection('user');
      final query =
      await usersRef.where('email', isEqualTo: email).limit(1).get();

      String userType;
      if (query.docs.isEmpty) {
        userType = '0';
        await usersRef.doc(user.uid).set({
          'id': user.uid,
          'user_type': userType,
          'start_date': '',
          'email': email,
          'name': user.displayName ?? '',
        });
      } else {
        final data = query.docs.first.data() as Map<String, dynamic>;
        userType = data['user_type'] ?? '0';
      }

      await pref.setString('user_id', user.uid);
      await pref.setString('user_type', userType);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => bottom_navigation()),
            (route) => false,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => showLoader = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => showLoader = true);
    try {
      final appleCredential =
      await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: appleCredential.authorizationCode,
      );
      final userCred = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      if (userCred.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => bottom_navigation()),
              (route) => false,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Apple sign-in failed: $e');
    } finally {
      if (mounted) setState(() => showLoader = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xffF6F4F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Center(
                child: PhysicalModel(
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 45),
              const Divider(
                height: 1,
                thickness: 1.5,
                color: Color(0xFF485370),
              ),
              const SizedBox(height: 24),

              // ← Wrapped in a Form so validate()/save() work
              Form(
                key: formKeyLogin,
                child: Column(
                  children: [
                    // Username
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE0E0E0), width: 3),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/icons/user.png',
                              height: 40,
                            ),
                          ),
                          Container(width: 2.5, height: 45, color: Color(0xFFE0E0E0)),
                          Expanded(
                            child: TextFormField(
                              controller: userNameController,
                              decoration: const InputDecoration(
                                hintText: 'Username',
                                hintStyle: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                isDense: true,
                              ),
                              validator: (s) =>
                              (s == null || s.trim().isEmpty) ? 'Enter username' : null,
                              onSaved: (s) => userNameController.text = s!.trim(),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE0E0E0), width: 3),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/icons/lock.png',
                              height: 40,
                            ),
                          ),
                          Container(width: 2.5, height: 45, color: Color(0xFFE0E0E0)),
                          Expanded(
                            child: TextFormField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                isDense: true,
                              ),
                              obscureText: true,
                              validator: (s) =>
                              (s == null || s.trim().isEmpty) ? 'Enter password' : null,
                              onSaved: (s) => passwordController.text = s!.trim(),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Log In button / loader
                    showLoader
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: userAccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0F75BC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(
                                color: Color(0xFF485370), width: 2),
                          ),
                        ),
                        child: const Text('Log in'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot Password?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF485370),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('or', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              // Social row unchanged...
              Center(
                  child: GestureDetector(
                    onTap: _handleGoogleSignIn,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFCCCCCC)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/google_logo.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: _handleAppleSignIn,
                  //   child: Container(
                  //     width: 50,
                  //     height: 50,
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(color: Color(0xFFCCCCCC)),
                  //       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  //     ),
                  //     child: const Icon(Icons.apple, size: 24, color: Color(0xFF485370)),
                  //   ),
                  // ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
