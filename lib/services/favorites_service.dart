import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _localKey = 'guest_favorites';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  // ---------- Client connecté (Firestore) ----------
  Stream<Set<String>> watch(String uid) => _col(uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());

  Future<void> add(String uid, String productId) => _col(uid)
      .doc(productId)
      .set({'addedAt': FieldValue.serverTimestamp()});

  Future<void> remove(String uid, String productId) =>
      _col(uid).doc(productId).delete();

  // ---------- Visiteur (stockage local) ----------
  Future<Set<String>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_localKey) ?? []).toSet();
  }

  Future<void> saveLocal(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localKey, ids.toList());
  }

  /// Envoie les favoris du visiteur vers le compte, puis vide le stockage local
  Future<void> mergeLocalInto(String uid) async {
    final local = await loadLocal();
    if (local.isEmpty) return;
    final batch = _db.batch();
    for (final id in local) {
      batch.set(_col(uid).doc(id), {'addedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey);
  }
} 