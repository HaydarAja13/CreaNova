import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  /// Read once
  Future<Map<String, dynamic>> getProfile() async {
    final doc = await _col.doc(_uid).get();
    return doc.data() ?? {};
  }

  /// Live stream for UI (Home/Profile)
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamMe() {
    return _col.doc(_uid).snapshots();
  }

  /// Ensure document exists with default counters
  Future<void> ensureDefaults() async {
    await _col.doc(_uid).set({
      'totalMoney': FieldValue.increment(0),
      'totalTrashKg': FieldValue.increment(0),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Partial upsert of profile fields (preserves counters)
  Future<void> upsertProfile({
    String? displayName,
    String? photoURL,
    String? email,
    String? address,
    double? lat,
    double? lng,
    String? geohash,
  }) async {
    final data = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (photoURL    != null) 'photoURL': photoURL,
      if (email       != null) 'email': email,
      if (address     != null) 'address': address,
      if (lat         != null) 'lat': lat,
      if (lng         != null) 'lng': lng,
      if (geohash     != null) 'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),

      // keep counters present even if never set before
      'totalMoney': FieldValue.increment(0),
      'totalTrashKg': FieldValue.increment(0),
    };

    await _col.doc(_uid).set(data, SetOptions(merge: true));
  }

  /// Atomic increments — call after successful actions
  Future<void> addMoney(num amount) async {
    await _col.doc(_uid).set({
      'totalMoney': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addTrashKg(num kg) async {
    await _col.doc(_uid).set({
      'totalTrashKg': FieldValue.increment(kg),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
