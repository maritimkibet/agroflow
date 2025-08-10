import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _currentUser;
  // ignore: unused_field
  DocumentSnapshot<Map<String, dynamic>>? _userDoc;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  File? _pickedImage;
  String? _photoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (!doc.exists) {
        _showSnackBar('User profile not found.');
        return;
      }
      final data = doc.data()!;
      setState(() {
        _userDoc = doc;
        _nameController.text = data['displayName'] ?? '';
        _emailController.text = _currentUser!.email ?? '';
        _photoUrl = data['photoUrl'] ?? '';
      });
    } catch (e) {
      _showSnackBar('Failed to load user data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadProfilePicture(String uid) async {
    if (_pickedImage == null) return _photoUrl;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('user_profiles/$uid.jpg');
      final uploadTask = storageRef.putFile(_pickedImage!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _showSnackBar('Failed to upload image: $e');
      return null;
    }
  }

  Future<bool> _reauthenticate(String currentPassword) async {
    if (_currentUser == null || _currentUser!.email == null) return false;

    try {
      final cred = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );
      await _currentUser!.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Re-authentication failed: ${e.message}');
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty) {
      _showSnackBar('Name cannot be empty.');
      return;
    }
    if (newEmail.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(newEmail)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    final wantsEmailChange = newEmail != (_currentUser!.email ?? '');
    final wantsPasswordChange = _newPasswordController.text.isNotEmpty ||
        _confirmNewPasswordController.text.isNotEmpty;

    // Password validation
    if (wantsPasswordChange) {
      if (_newPasswordController.text != _confirmNewPasswordController.text) {
        _showSnackBar('New passwords do not match.');
        return;
      }
      if (_newPasswordController.text.length < 6) {
        _showSnackBar('New password must be at least 6 characters.');
        return;
      }
    }

    if ((wantsEmailChange || wantsPasswordChange) && _currentPasswordController.text.isEmpty) {
      _showSnackBar('Please enter your current password to confirm changes.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Reauthenticate if needed
      if (wantsEmailChange || wantsPasswordChange) {
        final success = await _reauthenticate(_currentPasswordController.text);
        if (!success) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Upload profile picture if changed
      final uploadedPhotoUrl = await _uploadProfilePicture(_currentUser!.uid);
      final updatedPhotoUrl = uploadedPhotoUrl ?? _photoUrl ?? '';

      // Update Firebase Auth profile (name and photo)
      await _currentUser!.updateDisplayName(newName);
      if (updatedPhotoUrl.isNotEmpty) {
        await _currentUser!.updatePhotoURL(updatedPhotoUrl);
      }

      // Update Firestore user document
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'displayName': newName,
        'photoUrl': updatedPhotoUrl,
      });

      // Update email if changed
      if (wantsEmailChange) {
        // ignore: deprecated_member_use
        await _currentUser!.updateEmail(newEmail);
      }

      // Update password if changed
      if (wantsPasswordChange) {
        await _currentUser!.updatePassword(_newPasswordController.text);
      }

      await _currentUser!.reload();
      _currentUser = _auth.currentUser;

      setState(() {
        _photoUrl = updatedPhotoUrl;
        _pickedImage = null;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      });

      _showSnackBar('Profile updated successfully.');
    } catch (e) {
      _showSnackBar('Failed to update profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Selectively clear Hive boxes
  Future<void> _clearHiveBoxes() async {
    try {
      final boxNamesToClear = ['taskBox', 'userBox', 'settingsBox']; // your Hive box names here
      for (final boxName in boxNamesToClear) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
          await Hive.deleteBoxFromDisk(boxName);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to clear local storage: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout? All local data will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Sign out from Firebase
      await _auth.signOut();

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Clear selected Hive boxes
      await _clearHiveBoxes();

      // 4. Navigate to login and remove all previous routes (app restart effect)
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _showSnackBar('Logout failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _pickedImage != null
        ? FileImage(_pickedImage!)
        : (_photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _currentUser == null
          ? const Center(child: Text('No user logged in'))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Profile picture, tap to change',
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(80),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: imageProvider as ImageProvider<Object>?,
                          child: imageProvider == null
                              ? const Icon(Icons.person, size: 60, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap profile picture to change',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 30),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Change Password',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmNewPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout'),
                        onPressed: _isLoading ? null : _confirmLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
