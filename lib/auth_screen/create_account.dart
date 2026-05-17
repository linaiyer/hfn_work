// create_account.dart

import 'package:flutter/material.dart';
import 'package:hfn_work/auth_screen/login.dart';

// ─── NEW IMPORTS ──────────────────────────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
// ──────────────────────────────────────────────────────────────────────────────

import 'package:hfn_work/bottom_shet/bottom_navigation.dart';
import 'package:hfn_work/auth_screen/create_account_sso.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class create_account extends StatefulWidget {
  @override
  _create_account createState() => _create_account();
}

class _create_account extends State<create_account> {

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

  // ─── NEW: Google Sign-In Handler ─────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    // optional: trigger loader
    setState(() {});

    try {
      // 1) Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      // 2) Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3) Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4) Sign in with Firebase
      final UserCredential userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCred.user;
      if (user == null) return;

      // 5) Ensure Firestore has a user doc & save prefs
      final SharedPreferences pref = await SharedPreferences.getInstance();
      final userRef = FirebaseFirestore.instance.collection('user').doc(user.uid);
      final snapshot = await userRef.get();

      // Create display name from Google user data
      String displayName = '';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        // Fallback to email username part
        displayName = user.email!.split('@')[0];
      }

      if (!snapshot.exists) {
        await userRef.set({
          'id': user.uid,
          'user_type': '0',
          'start_date': '',
          'email': user.email,
          'name': displayName,
        });
      } else {
        // Update name if it's empty and we have a display name
        final data = snapshot.data() as Map<String, dynamic>;
        if ((data['name'] == null || data['name'].toString().isEmpty) && displayName.isNotEmpty) {
          await userRef.update({'name': displayName});
        }
      }
      await pref.setString('user_id', user.uid);
      await pref.setString('user_type', '0');

      // 6) Navigate into the app
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => bottom_navigation()),
            (route) => false,
      );
    } catch (e) {
      // handle errors however you like (e.g. show a Snackbar)
      print('Google sign-in error: $e');
    } finally {
      // optional: hide loader
      setState(() {});
    }
  }


  // ──────────────────────────────────────────────────────────────────────────────

  // ─── NEW: Apple Sign-In Handler (iOS only) ───────────────────────────────────
  Future<void> _handleAppleSignIn() async {
    setState(() {}); // If you want a loader, set a boolean here
    try {
      print('Starting Apple Sign In (create account)...');
      
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
      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      
      final User? user = userCred.user;
      if (user == null) {
        print('Firebase user is null');
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

      // Ensure Firestore has a user doc & save prefs
      final SharedPreferences pref = await SharedPreferences.getInstance();
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
      
      // Show user-friendly error message
      String errorMsg = 'Apple sign-in failed';
      if (e.toString().contains('cancelled')) {
        errorMsg = 'Sign-in was cancelled';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Network error. Please check your connection.';
      }
      
      // You can show a Snackbar or other UI feedback here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      setState(() {}); // reset loader boolean if you use one
    }
  }
  // ──────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xffF6F4F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: h * 0.08),

              // Logo
              Center(
                child: PhysicalModel(
                  color: Colors.transparent,
                  shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 45),

              // Divider
              const Divider(
                color: Color(0xFF485370),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 24),

              // Heading
              Text(
                'Create an account',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: const Color(0xFF485370),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Google button
              ElevatedButton(
                onPressed: _handleGoogleSignIn, // ─── UPDATED
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF485370),
                  elevation: 2,
                  shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/google_logo.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFCCCCCC),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (Platform.isIOS) ...[
                ElevatedButton(
                  onPressed: _handleAppleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF485370),
                    elevation: 2,
                    shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/apple_logo.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFFCCCCCC),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Apple',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'WorkSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // SSO button (unchanged)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => createAccountSSO(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF485370),
                  elevation: 2,
                  shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 49), // icon+divider space
                    Text(
                      'Continue with SSO',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF485370),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Footer link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => login()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color.fromRGBO(72, 83, 112, 0.8),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF0F75BC),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),        // Column
        ),          // Padding
      ),            // ConstrainedBox
    ),              // Center
  ),                // SingleChildScrollView
),                  // SafeArea
    );
  }
}
