import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/services/user_repository.dart'; // <-- 1. IMPORT UserRepository

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // <-- Tambahkan instance Firestore

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // 2. TAMBAHKAN ERROR HANDLING DENGAN TRY-CATCH
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Panggil createUserDocument untuk sinkronisasi data (opsional tapi bagus)
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      // Melempar kembali error agar UI bisa menampilkannya
      throw Exception(e.message);
    }
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 3. SECARA OTOMATIS MEMBUAT DOKUMEN PENGGUNA DI FIRESTORE
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateUsername({
    required String username,
  }) async {
    // 4. TAMBAHKAN NULL CHECK UNTUK KEAMANAN
    final user = currentUser;
    if (user == null) throw Exception("No user is currently signed in.");

    try {
      await user.updateDisplayName(username);
      // Juga update di Firestore
      await UserRepository().upsertProfile(displayName: username);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("No user is currently signed in.");

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Hapus dokumen Firestore sebelum menghapus akun auth
      await _firestore.collection('users').doc(user.uid).delete();

      await user.delete();
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("No user is currently signed in.");

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 5. FUNGSI HELPER BARU UNTUK MEMBUAT DOKUMEN PENGGUNA
  /// Membuat atau memperbarui dokumen user di Firestore dengan data dasar.
  Future<void> _createUserDocument(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);

    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Menggunakan .set dengan merge: true untuk upsert
    await userDocRef.set(userData, SetOptions(merge: true));
    // Memastikan counter default ada
    await UserRepository().ensureDefaults();
  }
}