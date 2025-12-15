import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController(); // NEW: License Field
  
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty ||
        _licenseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => _isLoading = true);

    // Hardcoded 'driver' role
    final error = await _auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: 'driver', // FORCE DRIVER ROLE
      name: _nameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else {
        // Success
        showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Application Submitted"),
            content: const Text("Your driver account has been created.\n\nPlease wait for Admin approval before logging in."),
            actions: [
              TextButton(
                onPressed: () => context.go('/'), 
                child: const Text("OK")
              )
            ],
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Driver Application", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
               const Icon(Icons.badge, size: 80, color: Color(0xFF00BFA6)).animate().fade().scale(),
               const SizedBox(height: 20),
               Text("Join the Fleet", style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey)),
               const SizedBox(height: 40),

               // Name
               TextField(
                 controller: _nameController,
                 decoration: InputDecoration(
                   labelText: 'Full Name',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   prefixIcon: const Icon(Icons.person),
                 ),
               ),
               const SizedBox(height: 15),

               // License Number (New)
               TextField(
                 controller: _licenseController,
                 decoration: InputDecoration(
                   labelText: 'Driving License Number',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   prefixIcon: const Icon(Icons.card_membership),
                 ),
               ),
               const SizedBox(height: 15),

               // Email
               TextField(
                 controller: _emailController,
                 decoration: InputDecoration(
                   labelText: 'Email',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   prefixIcon: const Icon(Icons.email),
                 ),
               ),
               const SizedBox(height: 15),

               // Password
               TextField(
                 controller: _passwordController,
                 obscureText: true,
                 decoration: InputDecoration(
                   labelText: 'Password',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   prefixIcon: const Icon(Icons.lock),
                 ),
               ),
               
               const SizedBox(height: 30),

               SizedBox(
                 width: double.infinity,
                 height: 55,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _handleSignUp,
                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA6)),
                   child: _isLoading 
                     ? const CircularProgressIndicator(color: Colors.white) 
                     : const Text('SUBMIT APPLICATION', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}