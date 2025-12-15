import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggedIn = false;

  AuthNotifier() {
    // Listen to Firebase Auth changes
    _auth.authStateChanges().listen((User? user) {
      _isLoggedIn = user != null;
      notifyListeners(); // Tell the router to refresh
    });
  }

  bool get isLoggedIn => _isLoggedIn;
}