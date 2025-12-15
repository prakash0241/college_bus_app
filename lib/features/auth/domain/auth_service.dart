import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // SIGN UP WITH TIMEOUT
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      print("1. Creating Auth User...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        print("2. Auth User Created. ID: ${user.uid}");
        
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          role: role,
          isApproved: role == 'student',
        );

        print("3. Saving to Firestore...");
        // Add a 10-second timeout to prevent infinite loading
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap())
            .timeout(const Duration(seconds: 10), onTimeout: () {
              throw "Database Timeout: Firestore is not responding.";
            });
            
        print("4. Firestore Save Complete!");
        return null; // Success
      }
      return 'User creation failed (User is null)';
    } on FirebaseAuthException catch (e) {
      return e.message; // e.g. "Email already in use"
    } catch (e) {
      print("ERROR: $e");
      // If Firestore fails, try to delete the "Zombie" auth user so they can try again
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
      }
      return "Error: $e";
    }
  }

  // LOGIN
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // GET USER ROLE
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      print("Error fetching role: $e");
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}