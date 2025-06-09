// create_account.dart

import 'package:flutter/material.dart';
import 'package:hfn_work/auth_screen/login.dart';

// ─── NEW IMPORTS ──────────────────────────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

      if (!snapshot.exists) {
        await userRef.set({
          'id': user.uid,
          'user_type': '0',
          'start_date': '',
          'email': user.email,
          'name': user.displayName ?? '',
        });
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
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: appleCredential.authorizationCode, // optional
      );

      UserCredential userCred =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (userCred.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => bottom_navigation()),
              (route) => false,
        );
      }
    } catch (e) {
      print('Apple sign-in error: $e');
    } finally {
      setState(() {}); // reset loader boolean if you use one
    }
  }
  // ──────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xffF6F4F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

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

              // Apple button
              // ElevatedButton(
              //   onPressed: _handleAppleSignIn, // ─── UPDATED
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.white,
              //     foregroundColor: const Color(0xFF485370),
              //     elevation: 2,
              //     shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
              //     side: const BorderSide(color: Color(0xFFCCCCCC)),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(24),
              //     ),
              //     padding: const EdgeInsets.symmetric(
              //       vertical: 14,
              //       horizontal: 16,
              //     ),
              //     alignment: Alignment.centerLeft,
              //   ),
                // child: Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     Icon(
                //       Icons.apple,
                //       size: 24,
                //       color: const Color(0xFF485370),
                //     ),
                //     const SizedBox(width: 12),
                //     Container(
                //       width: 1,
                //       height: 24,
                //       color: const Color(0xFFCCCCCC),
                //     ),
                //     const SizedBox(width: 12),
                //     Text(
                //       'Continue with Apple',
                //       style: theme.textTheme.bodyLarge?.copyWith(
                //         fontFamily: 'WorkSans',
                //         fontWeight: FontWeight.w600,
                //         fontSize: 16,
                //       ),
                //     ),
                //   ],
                // ),
              // ),
              // const SizedBox(height: 12),

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
              const Spacer(),

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
          ),
        ),
      ),
    );
  }
}
