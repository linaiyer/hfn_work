import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class pickAvatar extends StatefulWidget {
  @override
  _pickAvatar createState() => _pickAvatar();
}

class _pickAvatar extends State<pickAvatar> {
  List<Map<String, dynamic>> avatarImages = [];
  bool showLoader = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvatars();
  }

  Future<void> _fetchAvatars() async {
    setState(() => showLoader = true);
    final snapshot = await FirebaseFirestore.instance.collection('profileImage').get();
    final docs = snapshot.docs;
    avatarImages = docs.map((d) => d.data() as Map<String, dynamic>).toList();
    setState(() => showLoader = false);
  }

  Future<void> _uploadImageOnProfile(String imageUrl) async {
    setState(() => isUploading = true);
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    if (uid != null) {
      await FirebaseFirestore.instance.collection('user').doc(uid)
          .update({'user_profile': imageUrl});
      Fluttertoast.showToast(
        msg: 'Profile updated successfully',
        backgroundColor: const Color(0xFF0F75BC),
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
    setState(() => isUploading = false);
  }

  Widget _buildAvatarButton(String imageUrl) {
    return IconButton(
      onPressed: () => _uploadImageOnProfile(imageUrl),
      iconSize: 100,
      icon: ClipOval(
        child: Image.network(
          imageUrl,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 40, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF485370)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Pick Your Avatar',
                      style: TextStyle(
                          fontFamily: 'WorkSans', fontSize: 35, fontWeight: FontWeight.w600, color: Color(0xFF485370)),
                    ),
                    const SizedBox(width: 48), // placeholder for symmetry
                  ],
                ),
                const SizedBox(height: 5),
                const Divider(color: Color(0xFF485370)),
                const SizedBox(height: 20),
                if (showLoader)
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                if (!showLoader && avatarImages.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No Avatars Found!',
                        style: TextStyle(
                            fontFamily: 'WorkSans', fontSize: 24, fontWeight: FontWeight.w500, color: Color(0xFF485370)),
                      ),
                    ),
                  ),
                if (!showLoader && avatarImages.isNotEmpty)
                  Expanded(
                    child: Column(
                      children: [
                        // Top single avatar
                        if (avatarImages.length >= 1)
                          _buildAvatarButton(avatarImages[0]['image'] as String),
                        const SizedBox(height: 24),
                        // Next two avatars
                        if (avatarImages.length >= 3)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAvatarButton(avatarImages[1]['image'] as String),
                              _buildAvatarButton(avatarImages[2]['image'] as String),
                            ],
                          ),
                        if (avatarImages.length == 2)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAvatarButton(avatarImages[1]['image'] as String),
                            ],
                          ),
                        const SizedBox(height: 24),
                        // Next two avatars
                        if (avatarImages.length >= 5)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAvatarButton(avatarImages[3]['image'] as String),
                              _buildAvatarButton(avatarImages[4]['image'] as String),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0F75BC)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
