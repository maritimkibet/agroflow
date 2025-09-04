import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hybrid_storage_service.dart';
import '../services/update_service.dart';
import '../models/user.dart' as app_user;
import 'package:package_info_plus/package_info_plus.dart';

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
  // ignore: unused_field
  DocumentSnapshot<Map<String, dynamic>>? _userDoc;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final UpdateService _updateService = UpdateService();
  
  bool _checkingForUpdates = false;
  
  // Admin access

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
      // Try Firebase first
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        _fetchUserData();
      } else {
        // Fallback to local storage
        final localUser = _storageService.getCurrentUser();
        if (localUser != null) {
          _nameController.text = localUser.name;
          _emailController.text = localUser.email ?? '';
          _phoneController.text = localUser.phone ?? '';
        } else {
          // Create demo user for testing
          _nameController.text = 'Demo User';
          _emailController.text = 'demo@agroflow.com';
          _phoneController.text = '+254712345678';
        }
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      // Fallback to demo data
      _nameController.text = 'Demo User';
      _emailController.text = 'demo@agroflow.com';
      _phoneController.text = '+254712345678';
    }
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
        _phoneController.text = data['phone'] ?? '';
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
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
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
      // Use the correct box names from HiveService
      final boxNamesToClear = [
        'crop_tasks',
        'users', 
        'products',
        'crop_data',
        'settings',
        'sync_queue'
      ];
      
      for (final boxName in boxNamesToClear) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
          }
        } catch (e) {
          // Continue with other boxes if one fails
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
            Text('• Keep Data: Your tasks and settings will be saved for next login'),
            SizedBox(height: 8),
            Text('• Clear Data: All local data will be removed (your account stays safe)'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
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

  /// Logout while keeping local data (user can resume where they left off)
  Future<void> _logoutKeepData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Sync any pending data to Firebase before logout
      try {
        final hybridStorage = HybridStorageService();
        await hybridStorage.syncPendingItems();
      } catch (e) {
        // Sync failed, but continue with logout
        _showSnackBar('Some data may not be synced: $e');
      }

      // 2. Sign out from Firebase only
      await _auth.signOut();

      // 3. Navigate to auth wrapper (data preserved)
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      
      _showSnackBar('Logged out successfully. Your data is preserved.');
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

  /// Logout and clear all local data (fresh start)
  Future<void> _logoutClearData() async {
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

      // 4. Navigate to auth wrapper and remove all previous routes
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      
      _showSnackBar('Logged out and cleared all local data.');
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

  /// Confirm and delete user account permanently
  Future<void> _confirmDeleteAccount() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will PERMANENTLY delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Your user account'),
            Text('• All your farming tasks'),
            Text('• Your marketplace products'),
            Text('• Your profile and settings'),
            SizedBox(height: 16),
            Text(
              'This action CANNOT be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
            child: const Text('DELETE FOREVER'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteAccount();
    }
  }

  /// Delete user account and all associated data
  Future<void> _deleteAccount() async {
    if (_currentUser == null) return;

    // Get current password for reauthentication
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current password to confirm account deletion:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(passwordController.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Reauthenticate user
      final success = await _reauthenticate(password);
      if (!success) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Delete user data from Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).delete();

      // 3. Delete user's products from marketplace
      final productsQuery = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: _currentUser!.uid)
          .get();
      
      for (final doc in productsQuery.docs) {
        await doc.reference.delete();
      }

      // 4. Delete user's tasks from Firestore
      final tasksQuery = await _firestore
          .collection('crop_tasks')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();
      
      for (final doc in tasksQuery.docs) {
        await doc.reference.delete();
      }

      // 5. Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _clearHiveBoxes();

      // 6. Delete Firebase Auth account
      await _currentUser!.delete();

      // 7. Navigate to auth wrapper
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      
      _showSnackBar('Account deleted successfully.');
    } catch (e) {
      _showSnackBar('Failed to delete account: $e');
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

  void _handleAdminTap() {
    // Direct admin access - no need for multiple taps
    _showAdminAccessDialog();
  }

  void _showAdminAccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.blue),
            SizedBox(width: 8),
            Text('Admin Access'),
          ],
        ),
        content: const Text(
          'Access the administrative dashboard to manage users, content, and system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin_login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Access Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdatesManually() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateInfo = await _updateService.forceCheckForUpdates();
      
      if (updateInfo != null) {
        if (mounted) {
          await _updateService.showUpdateDialog(context, updateInfo);
        }
      } else {
        _showSnackBar('You have the latest version!');
      }
    } catch (e) {
      _showSnackBar('Failed to check for updates: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  IconData _getRoleIcon(app_user.UserRole role) {
    switch (role) {
      case app_user.UserRole.farmer:
        return Icons.agriculture;
      case app_user.UserRole.buyer:
        return Icons.shopping_cart;
      case app_user.UserRole.both:
        return Icons.swap_horiz;
    }
  }

  String _getRoleDisplayName(app_user.UserRole role) {
    switch (role) {
      case app_user.UserRole.farmer:
        return 'Farmer';
      case app_user.UserRole.buyer:
        return 'Buyer/Seller';
      case app_user.UserRole.both:
        return 'Farmer & Seller';
    }
  }

  String _getRoleDescription(app_user.UserRole role) {
    switch (role) {
      case app_user.UserRole.farmer:
        return 'Access to farming tools, tasks, and calendar';
      case app_user.UserRole.buyer:
        return 'Access to marketplace and trading features';
      case app_user.UserRole.both:
        return 'Full access to all farming and marketplace features';
    }
  }

  String _getUpgradeText(app_user.UserRole role) {
    switch (role) {
      case app_user.UserRole.farmer:
        return 'Add Selling Features';
      case app_user.UserRole.buyer:
        return 'Add Farming Features';
      case app_user.UserRole.both:
        return 'Already have all features';
    }
  }

  Future<void> _showRoleUpgradeDialog(app_user.User user) async {
    final newRole = user.role == app_user.UserRole.farmer ? app_user.UserRole.both : app_user.UserRole.both;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expand Your Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade from ${_getRoleDisplayName(user.role)} to ${_getRoleDisplayName(newRole)}'),
            const SizedBox(height: 16),
            const Text('You\'ll gain access to:'),
            const SizedBox(height: 8),
            if (user.role == app_user.UserRole.farmer) ...[
              const Text('• Marketplace for selling your produce'),
              const Text('• Product listing and management'),
              const Text('• Market price analysis'),
              const Text('• Customer communication tools'),
            ] else ...[
              const Text('• Farming task management'),
              const Text('• Crop calendar and planning'),
              const Text('• Weather-based farming advice'),
              const Text('• Agricultural AI assistant'),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All your current data will be preserved. This change is permanent.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Role'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _upgradeUserRole(user, newRole);
    }
  }

  Future<void> _upgradeUserRole(app_user.User user, app_user.UserRole newRole) async {
    try {
      setState(() => _isLoading = true);
      
      // Update user role
      user.role = newRole;
      
      // Save to both local and Firebase
      final storageService = HybridStorageService();
      await storageService.saveUserProfile(user);
      
      _showSnackBar('Role upgraded successfully! Restart the app to see new features.');
      
      // Show feature highlight tutorial
      if (mounted) {
        _showFeatureHighlights(newRole);
      }
      
    } catch (e) {
      _showSnackBar('Failed to upgrade role: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFeatureHighlights(app_user.UserRole newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Welcome to Your New Features!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Here\'s what\'s new for you:'),
            const SizedBox(height: 16),
            if (newRole == app_user.UserRole.both) ...[
              _buildFeatureHighlight(
                Icons.shopping_cart,
                'Marketplace Tab',
                'Tap the shopping cart icon to list your products for sale',
              ),
              _buildFeatureHighlight(
                Icons.add_shopping_cart,
                'Add Product Button',
                'Use the + button in marketplace to create new listings',
              ),
              _buildFeatureHighlight(
                Icons.psychology,
                'Enhanced AI',
                'AI assistant now provides selling and marketing advice',
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 30),

                    // App Version Section (for admin access)
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.blue),
                        title: const Text('App Information'),
                        subtitle: GestureDetector(
                          onTap: _handleAdminTap,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AgroFlow v1.0.0'),
                              Text('Tap for admin access', 
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Legal Section
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.description, color: Colors.green),
                            title: const Text('Terms & Conditions'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, '/terms_conditions');
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip, color: Colors.blue),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, '/privacy_policy');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 30),

                    // App Updates Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'App Updates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.system_update, color: Colors.green.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'App Version',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      GestureDetector(
                                        onTap: _handleAdminTap,
                                        child: FutureBuilder<PackageInfo>(
                                          future: PackageInfo.fromPlatform(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                                                style: TextStyle(color: Colors.grey.shade600),
                                              );
                                            }
                                            return Text(
                                              'Loading...',
                                              style: TextStyle(color: Colors.grey.shade600),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: _checkingForUpdates 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.refresh),
                                label: Text(_checkingForUpdates ? 'Checking...' : 'Check for Updates'),
                                onPressed: _checkingForUpdates ? null : _checkForUpdatesManually,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Role Management Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account Role',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<app_user.User?>(
                      future: Future.value(HybridStorageService().getCurrentUser()),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user == null) return const SizedBox();
                        
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(_getRoleIcon(user.role), color: Colors.green.shade600),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Role: ${_getRoleDisplayName(user.role)}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            _getRoleDescription(user.role),
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.role != app_user.UserRole.both) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.swap_horiz),
                                      label: Text(_getUpgradeText(user.role)),
                                      onPressed: () => _showRoleUpgradeDialog(user),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Sync Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Data Sync',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>>(
                      future: HybridStorageService().getSyncStatus(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final syncStatus = snapshot.data!;
                          final isOnline = syncStatus['isOnline'] as bool;
                          final pendingItems = syncStatus['pendingItems'] as int;
                          
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isOnline ? Icons.cloud_done : Icons.cloud_off,
                                        color: isOnline ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          color: isOnline ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (pendingItems > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$pendingItems pending',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (pendingItems > 0) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.sync),
                                        label: const Text('Sync Now'),
                                        onPressed: isOnline ? () async {
                                          try {
                                            await HybridStorageService().syncPendingItems();
                                            setState(() {});
                                            _showSnackBar('Sync completed successfully');
                                          } catch (e) {
                                            _showSnackBar('Sync failed: $e');
                                          }
                                        } : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 16),
                                Text('Checking sync status...'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_sync),
                        label: const Text('Force Sync All Data'),
                        onPressed: _isLoading ? null : () async {
                          try {
                            setState(() => _isLoading = true);
                            await HybridStorageService().forceSyncAll();
                            _showSnackBar('All data synced successfully');
                          } catch (e) {
                            _showSnackBar('Force sync failed: $e');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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
                    
                    // Legal Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Legal & Privacy',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.description, color: Colors.grey),
                            label: const Text('Terms & Conditions'),
                            onPressed: _isLoading ? null : () {
                              Navigator.pushNamed(context, '/terms_conditions');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.privacy_tip, color: Colors.grey),
                            label: const Text('Privacy Policy'),
                            onPressed: _isLoading ? null : () {
                              Navigator.pushNamed(context, '/privacy_policy');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Admin Access Section
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                        label: const Text('Admin Access'),
                        onPressed: _isLoading ? null : () {
                          Navigator.pushNamed(context, '/admin_login');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.orange),
                        label: const Text('Logout'),
                        onPressed: _isLoading ? null : _confirmLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text('Delete Account'),
                        onPressed: _isLoading ? null : _confirmDeleteAccount,
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
