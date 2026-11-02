import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../utils/loyalty.dart';
import '../utils/shipping.dart';
import 'payment_service.dart';

/// Erreur métier affichable telle quelle à l'utilisateur
class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Crée la commande dans une transaction :
  /// vérifie le stock et le montant, applique la remise de fidélité,
  /// décrémente le stock, crée la commande, met à jour le compteur et les
  /// points du client, puis vide le panier.
  Future<OrderModel> placeOrder({
    required String uid,
    required List<CartItem> cart,
    required ShippingInfo shipping,
    required String paymentMethod,
    required double expectedTotal,
    required bool useLoyalty,
    String? paymentReference,
  }) {
    if (cart.isEmpty) throw OrderException('Votre panier est vide.');

    final paid = paymentMethod == kPayCard;
    final orderRef = _db.collection('orders').doc();
    final products = _db.collection('products');
    final userRef = _db.collection('users').doc(uid);
    final cartCol = userRef.collection('cart');

    return _db.runTransaction<OrderModel>((tx) async {
      // 1. Lectures (toutes avant les écritures)
      final snaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in cart) {
        snaps.add(await tx.get(products.doc(item.productId)));
      }
      final userSnap = await tx.get(userRef);
      final udata = userSnap.data() ?? <String, dynamic>{};
      final orderCount = (udata['orderCount'] ?? 0).toInt() as int;
      final points = (udata['loyaltyPoints'] ?? 0).toInt() as int;

      // 2. Vérifications avec les prix et stocks actuels
      final items = <OrderItem>[];
      final newStocks = <int>[];
      var subtotal = 0.0;
      for (var i = 0; i < cart.length; i++) {
        final data = snaps[i].data();
        if (!snaps[i].exists || data == null) {
          throw OrderException(
              'Un produit de votre panier n\'est plus disponible.');
        }
        final name = (data['name'] ?? '') as String;
        final stock = (data['stock'] ?? 0).toInt() as int;
        final price = (data['price'] ?? 0).toDouble() as double;
        final qty = cart[i].quantity;

        if (qty > stock) {
          throw OrderException(stock <= 0
              ? '« $name » est en rupture de stock.'
              : 'Stock insuffisant pour « $name » ($stock disponible(s)).');
        }
        subtotal += price * qty;
        newStocks.add(stock - qty);
        items.add(OrderItem(
            productId: cart[i].productId,
            name: name,
            price: price,
            quantity: qty));
      }
      subtotal = double.parse(subtotal.toStringAsFixed(2));
      final fee = shippingFor(subtotal);

      // remise de fidélité calculée avec les points réels de la base
      final loyalty =
          applyLoyalty(subtotal: subtotal, points: points, use: useLoyalty);
      final total =
          double.parse((subtotal - loyalty.discount + fee).toStringAsFixed(2));

      // le montant payé doit correspondre au total recalculé
      if ((total - expectedTotal).abs() > 0.01) {
        throw OrderException('Le montant a changé (prix ou points de '
            'fidélité). Vérifiez votre commande puis réessayez.');
      }

      final newCount = orderCount + 1;
      final earned = pointsEarnedFor(newCount);

      // 3. Écritures
      for (var i = 0; i < cart.length; i++) {
        tx.update(products.doc(cart[i].productId), {
          'stock': newStocks[i],
          'popularity': FieldValue.increment(cart[i].quantity),
        });
      }

      tx.set(orderRef, {
        'userId': uid,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'shippingFee': fee,
        'discount': loyalty.discount,
        'pointsUsed': loyalty.pointsUsed,
        'pointsEarned': earned,
        'total': total,
        'address': shipping.formatted,
        'shipping': shipping.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'en_attente',
        'paymentStatus': paid ? 'paye' : 'en_attente',
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'paidAt': paid ? FieldValue.serverTimestamp() : null,
        'deliveryCompanyId': null,
        'deliveryStatus': 'en_preparation',
      });

      // compteur de commandes et points : mis à jour avec la commande
      tx.update(userRef, {
        'orderCount': newCount,
        'loyaltyPoints': points - loyalty.pointsUsed + earned,
        'lastOrderId': orderRef.id,
      });

      for (final item in cart) {
        tx.delete(cartCol.doc(item.productId));
      }

      return OrderModel(
        id: orderRef.id,
        userId: uid,
        items: items,
        subtotal: subtotal,
        shippingFee: fee,
        discount: loyalty.discount,
        pointsUsed: loyalty.pointsUsed,
        pointsEarned: earned,
        total: total,
        address: shipping.formatted,
        shipping: shipping,
        createdAt: DateTime.now(),
        paymentStatus: paid ? 'paye' : 'en_attente',
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        paidAt: paid ? DateTime.now() : null,
      );
    });
  }

  /// Commandes d'un client, de la plus récente à la plus ancienne.
  /// Le tri se fait ici : cela évite de créer un index composite dans Firestore.
  Stream<List<OrderModel>> watchByUser(String uid) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
      final now = DateTime.now();
      list.sort((a, b) =>
          (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      return list;
    });
  }
}