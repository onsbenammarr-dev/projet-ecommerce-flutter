import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

enum CheckoutStage { idle, paying, saving }

class OrderController extends ChangeNotifier {
  final OrderService _orders = OrderService();
  final PaymentService _payments = PaymentService();

  CheckoutStage stage = CheckoutStage.idle;
  String? error;
  bool paymentRefused = false;

  bool get isPlacing => stage != CheckoutStage.idle;

  void _setStage(CheckoutStage s) {
    stage = s;
    notifyListeners();
  }

  /// Paie (si carte) puis crée la commande.
  /// Renvoie la commande, ou null : le message est alors dans [error]
  /// et [paymentRefused] indique un paiement refusé (panier conservé).
  Future<OrderModel?> placeOrder({
    required String uid,
    required List<CartItem> cart,
    required ShippingInfo shipping,
    required String method,
    required double expectedTotal,
    required bool useLoyalty,
    String cardNumber = '',
    String expiry = '',
    String cvv = '',
  }) async {
    error = null;
    paymentRefused = false;
    String? reference;

    try {
      if (method == kPayCard) {
        _setStage(CheckoutStage.paying);
        final result = await _payments.chargeCard(
          amount: expectedTotal,
          cardNumber: cardNumber,
          expiry: expiry,
          cvv: cvv,
        );
        if (!result.approved) {
          error = result.message ?? 'Paiement refusé.';
          paymentRefused = true;
          _setStage(CheckoutStage.idle);
          return null;
        }
        reference = result.reference;
      }

      _setStage(CheckoutStage.saving);
      final order = await _orders.placeOrder(
        uid: uid,
        cart: cart,
        shipping: shipping,
        paymentMethod: method,
        expectedTotal: expectedTotal,
        useLoyalty: useLoyalty,
        paymentReference: reference,
      );
      _setStage(CheckoutStage.idle);
      return order;
    } on OrderException catch (e) {
      error = e.message;
    } on FirebaseException catch (e) {
      error = e.code == 'permission-denied'
          ? 'Accès refusé : vérifiez les règles Firestore.'
          : 'Impossible d\'enregistrer la commande. Vérifiez votre connexion.';
    } catch (_) {
      error = 'Une erreur est survenue. Réessayez.';
    }

    // échec après un paiement accepté : remboursement automatique
    if (reference != null) {
      try {
        await _payments.refund(reference);
      } catch (_) {}
      error = '$error Votre paiement a été annulé.';
    }
    _setStage(CheckoutStage.idle);
    return null;
  }

  /// Flux en direct des commandes d'un client
  Stream<List<OrderModel>> watchByUser(String uid) =>
      _orders.watchByUser(uid);
}