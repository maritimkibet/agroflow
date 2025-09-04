import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hybrid_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final HybridStorageService _storageService = HybridStorageService();

  User? _currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  File? _pickedImage;
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        _fetchUserData();
      } else {
        final localUser = _storageService.getCurrentUser();
        if (localUser != null) {
          _nameController.text = localUser.name;
          _emailController.text = localUser.email ?? '';
          _phoneController.text = localUser.phone ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['displayName'] ?? '';
          _emailController.text = _currentUser!.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _photoUrl = data['photoUrl'] ?? '';
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load user data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
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
      return await snapshot.ref.getDownloadURL();
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
    final wantsPasswordChange = _newPasswordController.text.isNotEmpty;

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

    setState(() => _isLoading = true);

    try {
      if (wantsEmailChange || wantsPasswordChange) {
        final success = await _reauthenticate(_currentPasswordController.text);
        if (!success) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final uploadedPhotoUrl = await _uploadProfilePicture(_currentUser!.uid);
      final updatedPhotoUrl = uploadedPhotoUrl ?? _photoUrl ?? '';

      await _currentUser!.updateDisplayName(newName);
      if (updatedPhotoUrl.isNotEmpty) {
        await _currentUser!.updatePhotoURL(updatedPhotoUrl);
      }

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'displayName': newName,
        'photoUrl': updatedPhotoUrl,
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      });

      if (wantsEmailChange) {
        await _currentUser!.verifyBeforeUpdateEmail(newEmail);
        _showSnackBar('Email verification sent. Please check your email.');
      }

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearHiveBoxes() async {
    try {
      final boxNamesToClear = [
        'crop_tasks', 'users', 'products', 'crop_data', 'settings', 'sync_queue'
      ];
      
      for (final boxName in boxNamesToClear) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
          }
        } catch (e) {
          debugPrint('Failed to clear box $boxName: $e');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to clear local storage: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Options'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose how you want to logout:'),
            SizedBox(height: 16),
            Text('• Keep Data: Your tasks and settings will be saved'),
            SizedBox(height: 8),
            Text('• Clear Data: All local data will be removed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('keep_data'),
            child: const Text('Keep Data'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(context).pop('clear_data'),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (result == 'keep_data') {
      await _logoutKeepData();
    } else if (result == 'clear_data') {
      await _logoutClearData();
    }
  }

  Future<void> _logoutKeepData() async {
    try {
      setState(() => _isLoading = true);
      
      try {
        await _storageService.syncPendingItems();
      } catch (e) {
        _showSnackBar('Some data may not be synced: $e');
      }

      await _auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      _showSnackBar('Logged out successfully. Your data is preserved.');
    } catch (e) {
      _showSnackBar('Logout failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logoutClearData() async {
    try {
      setState(() => _isLoading = true);

      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _clearHiveBoxes();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      _showSnackBar('Logged out and cleared all local data.');
    } catch (e) {
      _showSnackBar('Logout failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    _phoneController.dispose();
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
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(80),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: imageProvider as ImageProvider<Object>?,
                  child: imageProvider == null
                      ? Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade100,
                          ),
                          child: Center(
                            child: Text(
                              _nameController.text.isNotEmpty 
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap to change profile picture',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Profile Form
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., +254712345678',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),

              // Change Password Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmNewPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 32),

              // Admin Access
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.pushNamed(context, '/admin_login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Admin Access'),
                ),
              ),
              const SizedBox(height: 16),

              // Legal Links
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pushNamed(context, '/terms_conditions');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Terms'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pushNamed(context, '/privacy_policy');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Privacy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _confirmLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}