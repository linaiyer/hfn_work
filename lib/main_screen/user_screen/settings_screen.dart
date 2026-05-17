import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/main_screen/user_screen/additional_resources.dart';
import 'package:hfn_work/main_screen/terms_of_use.dart';
import 'package:hfn_work/main_screen/user_screen/notification_settings.dart';

class settings_screen extends StatefulWidget {
  @override
  _settings_screen createState() => _settings_screen();
}

class _settings_screen extends State<settings_screen> {
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .get();
      if (doc.exists) setState(() => profileData = doc.data());
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => login()),
          (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F4F5),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontFamily: 'WorkSans',
              color: Color(0xFF485370),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.',
            style: TextStyle(
              fontFamily: 'WorkSans',
              color: Color(0xFF485370),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
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
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F75BC)),
              ),
            );
          },
        );

        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('user_id');
        
        if (uid != null) {
          // Delete user data from all Firebase collections
          final firestore = FirebaseFirestore.instance;
          
          // Delete from user collection
          await firestore.collection('user').doc(uid).delete();
          
          // Delete from listeningStats collection
          final listeningStatsQuery = await firestore
              .collection('listeningStats')
              .where('user_id', isEqualTo: uid)
              .get();
          for (var doc in listeningStatsQuery.docs) {
            await doc.reference.delete();
          }
          
          // Delete from watchDataTable collection
          final watchDataQuery = await firestore
              .collection('watchDataTable')
              .where('user_id', isEqualTo: uid)
              .get();
          for (var doc in watchDataQuery.docs) {
            await doc.reference.delete();
          }
          
          // Delete from profileImage collection
          final profileImageQuery = await firestore
              .collection('profileImage')
              .where('user_id', isEqualTo: uid)
              .get();
          for (var doc in profileImageQuery.docs) {
            await doc.reference.delete();
          }
        }

        // Try to delete Firebase Auth user (may fail if not recently authenticated)
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) await user.delete();
        } catch (_) {
          // Auth user deletion failed — sign out instead, Firestore data is gone
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }

        // Sign out from Google if applicable
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}

        // Clear local preferences and navigate to login
        await prefs.clear();

        if (mounted) {
          Navigator.of(context).pop(); // close loading dialog
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => login()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting account: $e',
                style: const TextStyle(fontFamily: 'WorkSans'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = () {
      final n = profileData?['name'] as String?;
      if (n != null && n.isNotEmpty) return n;
      final u = profileData?['userName'] as String?;
      if (u != null && u.isNotEmpty) return u;
      return 'User';
    }();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF485370)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'WorkSans',
            color: Color(0xFF485370),
            fontSize: 35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Settings options list
              Expanded(
                child: ListView(
                  children: [
                    _buildTile(
                      iconAsset: 'assets/images/book.png',
                      label: 'Additional Resources',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdditionalResources()),
                      ),
                    ),
                    _buildTile(
                      iconAsset: 'assets/images/terms.png',
                      label: 'Terms and Conditions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TermsOfUse()),
                      ),
                    ),
                    _buildTile(
                      iconAsset: 'assets/images/bell.png',
                      label: 'Notification Settings',
                      onTap: () => Navigator.push (
                        context,
                        MaterialPageRoute(builder: (_) => notification_settings())
                      ),
                    ),
                  ],
                ),
              ),

              // User info & logout
              Text(
                'Logged in as',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  color: Color(0xFF485370),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF485370),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0F75BC),
                    foregroundColor: const Color(0xFF485370),
                    elevation: 3,
                    shadowColor: const Color.fromRGBO(0, 0, 0, 0.9),
                    side: const BorderSide(color: Color(0xFF485370)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    alignment: Alignment.center,
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(fontFamily: 'WorkSans', fontWeight: FontWeight.w700, fontSize: 25,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color.fromRGBO(0, 0, 0, 0.9),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    alignment: Alignment.center,
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(fontFamily: 'WorkSans', fontWeight: FontWeight.w700, fontSize: 25,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 130, // adjust this value to increase card height
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          leading: Image.asset(
            iconAsset,
            width: 90,
            height: 90,
          ),
          title: Text(
            label,
            style: const TextStyle(
              fontFamily: 'WorkSans',
              color: Color(0xFF485370),
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
