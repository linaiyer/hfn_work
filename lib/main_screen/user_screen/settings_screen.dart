import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    final name = profileData?['name'] as String? ?? 'Your Name';

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
