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
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:hfn_work/bottom_shet/bottom_navigation.dart';
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

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

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

      // Create display name from Google user data
      String displayName = '';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName!;
      } else if (email.isNotEmpty) {
        // Fallback to email username part
        displayName = email.split('@')[0];
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
          'name': displayName,
        });
      } else {
        final data = query.docs.first.data() as Map<String, dynamic>;
        userType = data['user_type'] ?? '0';
        // Update name if it's empty and we have a display name
        if ((data['name'] == null || data['name'].toString().isEmpty) && displayName.isNotEmpty) {
          await query.docs.first.reference.update({'name': displayName});
        }
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
      print('Starting Apple Sign In...');
      
      // Generate nonce for security
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      
      print('Getting Apple ID credential...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      
      print('Apple credential received: ${appleCredential.userIdentifier}');
      print('Email: ${appleCredential.email}');
      print('Given name: ${appleCredential.givenName}');
      print('Family name: ${appleCredential.familyName}');
      
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      
      print('Signing in with Firebase...');
      final userCred = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCred.user;
      
      if (user == null) {
        print('Firebase user is null');
        Fluttertoast.showToast(msg: 'Apple sign-in failed: no user');
        return;
      }
      
      print('Firebase user created/signed in: ${user.uid}');
      print('User email: ${user.email}');
      print('User displayName: ${user.displayName}');

      // Create display name from Apple credential (only available on first sign-in)
      String displayName = '';
      if (appleCredential.givenName != null && appleCredential.familyName != null) {
        displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        print('Using Apple credential name: $displayName');
      } else if (appleCredential.givenName != null) {
        displayName = appleCredential.givenName!;
        print('Using Apple given name: $displayName');
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName!;
        print('Using Firebase displayName: $displayName');
      } else if (user.email != null) {
        // Fallback to email username part
        displayName = user.email!.split('@')[0];
        print('Using email fallback: $displayName');
      } else {
        displayName = 'Apple User';
        print('Using default fallback name');
      }

      final pref = await SharedPreferences.getInstance();
      final usersRef = FirebaseFirestore.instance.collection('user');
      
      // Use the Firebase UID as the document ID for consistency
      final userDocRef = usersRef.doc(user.uid);
      final userDoc = await userDocRef.get();

      String userType = '0';
      
      if (!userDoc.exists) {
        print('Creating new user document...');
        await userDocRef.set({
          'id': user.uid,
          'user_type': userType,
          'start_date': '',
          'email': user.email ?? '',
          'name': displayName,
          'provider': 'apple',
          'created_at': FieldValue.serverTimestamp(),
        });
        print('User document created successfully');
      } else {
        print('User document already exists, updating if needed...');
        final data = userDoc.data() as Map<String, dynamic>;
        userType = data['user_type'] ?? '0';
        
        // Update name if it's empty and we have a display name
        Map<String, dynamic> updates = {};
        if ((data['name'] == null || data['name'].toString().isEmpty) && displayName.isNotEmpty) {
          updates['name'] = displayName;
        }
        if (data['email'] == null || data['email'].toString().isEmpty) {
          updates['email'] = user.email ?? '';
        }
        
        if (updates.isNotEmpty) {
          await userDocRef.update(updates);
          print('User document updated with: $updates');
        }
      }

      await pref.setString('user_id', user.uid);
      await pref.setString('user_type', userType);
      print('SharedPreferences saved');

      print('Navigating to app...');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => bottom_navigation()),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      print('Apple sign-in error: $e');
      print('Stack trace: $stackTrace');
      
      String errorMsg = 'Apple sign-in failed';
      if (e.toString().contains('cancelled')) {
        errorMsg = 'Sign-in was cancelled';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Network error. Please check your connection.';
      }
      
      Fluttertoast.showToast(msg: errorMsg);
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

              // Social row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
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
                  if (Platform.isIOS) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _handleAppleSignIn,
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
                            'assets/icons/apple_logo.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
