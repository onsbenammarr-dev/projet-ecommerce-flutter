import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  Stream<List<CartItem>> watchCart(String uid) {
    return _col(uid).snapshots().map((snap) =>
        snap.docs.map((d) => CartItem.fromMap(d.id, d.data())).toList());
  }

  Future<void> setQuantity(String uid, String productId, int quantity) =>
      _col(uid).doc(productId).set({'quantity': quantity});

  Future<void> remove(String uid, String productId) =>
      _col(uid).doc(productId).delete();

  Future<void> clear(String uid) async {
    final snap = await _col(uid).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}