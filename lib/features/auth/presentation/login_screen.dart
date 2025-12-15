import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../domain/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? role; 
  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false; 

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // 1. LOAD SAVED INFO
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);

    // 2. SAVE INFO IF CHECKED
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }

    // 3. ATTEMPT SIGN IN
    final error = await _auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    if (!mounted) return;

    if (error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await _auth.getUserRole(user.uid);
        
        if (!mounted) return;

        // ============================================================
        // 🔒 SECURITY FIX: STRICT ROLE CHECK
        // ============================================================
        // This blocks Admins from using Driver Portal (and vice versa)
        if (widget.role != null && role != widget.role) {
          
          // 1. Sign them out immediately
          await FirebaseAuth.instance.signOut();
          
          setState(() => _isLoading = false);
          
          // 2. Show Error Message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Access Denied! You are a $role, not a ${widget.role}."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            )
          );
          return; // STOP HERE. Do not navigate.
        }
        // ============================================================

        setState(() => _isLoading = false);

        // Navigate based on verified role
        if (role == 'driver') {
          context.go('/driver-dashboard');
        } else if (role == 'admin') {
          context.go('/admin-dashboard');
        } else {
          context.go('/student-home');
        }
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email first"), backgroundColor: Colors.orange));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Reset Email Sent"),
          content: Text("Check your inbox at $email"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.role == 'driver';
    final themeColor = isDriver ? const Color(0xFF00BFA6) : const Color(0xFFFF6584);
    final title = isDriver ? "Driver Login" : "Admin Portal";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black, onPressed: () => context.go('/')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(isDriver ? Icons.directions_bus : Icons.security, size: 80, color: themeColor).animate().scale(duration: 500.ms),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, 
                decoration: InputDecoration(
                  labelText: 'Password', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),

              // REMEMBER ME + FORGOT PASSWORD ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: themeColor,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text("Forgot Password?", style: TextStyle(color: themeColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('LOGIN', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (isDriver)
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: Text("New Driver? Apply Here", style: TextStyle(color: themeColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}