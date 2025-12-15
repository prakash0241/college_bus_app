import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Current User
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<UserModel> login(String email, String password) async {
    try {
      // 1. Auth with Firebase
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // 2. Fetch User Role from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception("User record not found in database");
      }

      // 3. Convert to Model
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign Up (Driver/Admin)
  Future<void> signUp({
    required String email, 
    required String password, 
    required String name, 
    required UserRole role
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        name: name,
        role: role,
        isApproved: role == UserRole.student ? true : false, // Drivers need approval
      );

      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
