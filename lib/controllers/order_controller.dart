import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _service = OrderService();

  bool isPlacing = false;
  String? error;

  /// Renvoie la commande créée, ou null (le message est alors dans [error])
  Future<OrderModel?> placeOrder({
    required String uid,
    required List<CartItem> cart,
    required ShippingInfo shipping,
  }) async {
    isPlacing = true;
    error = null;
    notifyListeners();

    OrderModel? order;
    try {
      order = await _service.placeOrder(
          uid: uid, cart: cart, shipping: shipping);
    } on OrderException catch (e) {
      error = e.message;
    } on FirebaseException catch (e) {
      error = e.code == 'permission-denied'
          ? 'Accès refusé : vérifiez les règles Firestore.'
          : 'Impossible de passer la commande. Vérifiez votre connexion.';
    } catch (_) {
      error = 'Une erreur est survenue. Réessayez.';
    }

    isPlacing = false;
    notifyListeners();
    return order;
  }

  /// Flux en direct des commandes d'un client
  Stream<List<OrderModel>> watchByUser(String uid) =>
      _service.watchByUser(uid);
}