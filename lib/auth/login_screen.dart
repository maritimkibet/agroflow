import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/error_service.dart';
import '../services/validation_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ErrorService.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToRegister() {
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Welcome Back'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Sign in to AgroFlow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Continue your farming journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: ValidationService.validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) => ValidationService.validateRequired(value, 'Password'),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: _goToRegister,
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
