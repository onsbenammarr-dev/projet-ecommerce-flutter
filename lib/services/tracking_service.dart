import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/courier_position.dart';

/// Position du livreur : un seul document par commande, réécrit à chaque déplacement
class TrackingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String orderId) => _db
      .collection('orders')
      .doc(orderId)
      .collection('tracking')
      .doc('current');

  /// Côté client : flux de la position du livreur (null si aucune)
  Stream<CourierPosition?> watch(String orderId) {
    return _doc(orderId).snapshots().map((snap) {
      final d = snap.data();
      if (d == null) return null;
      return CourierPosition(
        lat: (d['lat'] as num).toDouble(),
        lng: (d['lng'] as num).toDouble(),
        updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  /// Côté livreur : envoie la position
  Future<void> publish(String orderId, double lat, double lng) => _doc(orderId)
      .set({'lat': lat, 'lng': lng, 'updatedAt': FieldValue.serverTimestamp()});

  /// Côté livreur : supprime la position (fin du partage)
  Future<void> clear(String orderId) => _doc(orderId).delete();
}