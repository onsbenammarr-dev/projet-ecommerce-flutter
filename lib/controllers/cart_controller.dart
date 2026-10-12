import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartController extends ChangeNotifier {
  final CartService _service = CartService();
  StreamSubscription<List<CartItem>>? _sub;
  String? _uid;
  bool _disposed = false;

  List<CartItem> _items = [];
  String? error;

  List<CartItem> get items => _items;

    /// Vrai si un utilisateur est connecté (panier actif)
  bool get isBound => _uid != null;
  /// Nombre total d'articles (pour le badge)
  int get totalQuantity => _items.fold(0, (s, i) => s + i.quantity);

  int quantityOf(String productId) {
    for (final i in _items) {
      if (i.productId == productId) return i.quantity;
    }
    return 0;
  }

  /// Appelé par le ProxyProvider à chaque changement d'utilisateur
  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = null;
    _items = [];
    error = null;

    if (uid != null) {
      _sub = _service.watchCart(uid).listen(
        (list) {
          _items = list;
          error = null;
          notifyListeners();
        },
        onError: (_) {
          error = 'Impossible de charger le panier.';
          notifyListeners();
        },
      );
    }
    // évite notifyListeners() pendant la construction des widgets
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  /// Renvoie null si OK, sinon le message d'erreur
  Future<String?> add(ProductModel p, {int qty = 1}) async {
    final uid = _uid;
    if (uid == null) return 'Connectez-vous pour utiliser le panier.';
    final newQty = quantityOf(p.id) + qty;
    if (newQty > p.stock) {
      return 'Stock insuffisant (${p.stock} disponible(s)).';
    }
    try {
      await _service.setQuantity(uid, p.id, newQty);
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  Future<String?> setQuantity(ProductModel p, int quantity) async {
    final uid = _uid;
    if (uid == null) return 'Connectez-vous pour utiliser le panier.';
    if (quantity <= 0) return remove(p.id);
    if (quantity > p.stock) {
      return 'Stock insuffisant (${p.stock} disponible(s)).';
    }
    try {
      await _service.setQuantity(uid, p.id, quantity);
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  Future<String?> remove(String productId) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      await _service.remove(uid, productId);
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  Future<String?> clear() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      await _service.clear(uid);
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}