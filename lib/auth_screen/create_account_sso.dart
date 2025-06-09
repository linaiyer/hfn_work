// create_account_sso.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/bottom_shet/bottom_navigation.dart';

class createAccountSSO extends StatefulWidget {
  @override
  _createAccountSSO createState() => _createAccountSSO();
}

class _createAccountSSO extends State<createAccountSSO> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool showLoader = false;

  Future<void> _createAccount() async {
    // 1) quick client-side validation
    if (!_formKey.currentState!.validate()) return;

    // 2) show spinner
    setState(() => showLoader = true);

    try {
      final usersRef = FirebaseFirestore.instance.collection('user');
      final desiredUsername = usernameController.text.trim();

      // 3) check for duplicate
      final exists = await usersRef
          .where('userName', isEqualTo: desiredUsername)
          .limit(1)
          .get();

      if (exists.docs.isNotEmpty) {
        // 4a) duplicate → hide spinner & toast
        if (mounted) setState(() => showLoader = false);
        Fluttertoast.showToast(msg: 'Username already taken');
        return;
      }

      // 4b) no duplicate → create new doc
      final docRef = usersRef.doc();
      await docRef.set({
        'id': docRef.id,
        'userName': desiredUsername,
        'password': passwordController.text.trim(),
        'user_type': '0',
        'start_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

      // 5) persist locally
      final pref = await SharedPreferences.getInstance();
      await pref.setString('user_id', docRef.id);
      await pref.setString('user_type', '0');

      // 6) turn spinner off before navigating
      if (mounted) setState(() => showLoader = false);

      // 7) and go!
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => bottom_navigation()),
            (r) => false,
      );
    } catch (e) {
      // 8) on any error → hide spinner & toast
      if (mounted) setState(() => showLoader = false);
      Fluttertoast.showToast(msg: 'Error creating account: $e');
    }
  }


  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xffF6F4F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

              // ─── Logo ───────────────────────────────────────────
              Center(
                child: PhysicalModel(
                  color: Colors.transparent,
                  shadowColor: const Color.fromRGBO(0, 0, 0, 0.8),
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 45),

              // ─── Divider ────────────────────────────────────────
              const Divider(
                height: 1,
                thickness: 1.5,
                color: Color(0xFF485370),
              ),
              const SizedBox(height: 24),

              // ─── Form ───────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [

                    // • Username Field
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 3,
                        ),
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
                          Container(
                            width: 2.5,
                            height: 45,
                            color: const Color(0xFFE0E0E0),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                hintText: 'Username',
                                hintStyle: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              validator: (s) {
                                if (s == null || s.trim().isEmpty) {
                                  return 'Enter a username';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // • Password Field
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 3,
                        ),
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
                          Container(
                            width: 2.5,
                            height: 45,
                            color: const Color(0xFFE0E0E0),
                          ),
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              obscureText: true,
                              validator: (s) {
                                if (s == null || s.trim().length < 6) {
                                  return 'Password must be ≥ 6 chars';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // • Create Button / Loader
                    showLoader
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F75BC),
                          foregroundColor: const Color(0xFFFBFBFB),
                          textStyle: const TextStyle(
                            fontFamily: 'WorkSans',
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(
                                color: Color(0xFF485370), width: 2),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Create an Account'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── “Already have an account? Log in” ─────────────
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => login()),
                  ),
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
