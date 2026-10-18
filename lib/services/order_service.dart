import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../utils/shipping.dart';

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
  /// vérifie le stock, calcule les frais, décrémente le stock,
  /// crée la commande et vide le panier.
  Future<OrderModel> placeOrder({
    required String uid,
    required List<CartItem> cart,
    required ShippingInfo shipping,
  }) {
    if (cart.isEmpty) throw OrderException('Votre panier est vide.');

    final orderRef = _db.collection('orders').doc();
    final products = _db.collection('products');
    final cartCol = _db.collection('users').doc(uid).collection('cart');

    return _db.runTransaction<OrderModel>((tx) async {
      // 1. Lectures (toutes avant les écritures)
      final snaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in cart) {
        snaps.add(await tx.get(products.doc(item.productId)));
      }

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
      final total = double.parse((subtotal + fee).toStringAsFixed(2));

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
        'discount': 0,
        'total': total,
        'address': shipping.formatted,
        'shipping': shipping.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'en_attente',
        'paymentStatus': 'en_attente',
        'paymentMethod': '',
        'deliveryCompanyId': null,
        'deliveryStatus': 'en_preparation',
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
        discount: 0,
        total: total,
        address: shipping.formatted,
        shipping: shipping,
        createdAt: DateTime.now(),
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