import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/favorites_service.dart';

class FavoritesController extends ChangeNotifier {
  final FavoritesService _service = FavoritesService();
  StreamSubscription<Set<String>>? _sub;
  String? _uid;
  bool _started = false;
  bool _disposed = false;
  Set<String> _ids = {};

  Set<String> get ids => _ids;

  /// Vrai si un utilisateur est connecté (favoris dans Firestore)
  bool get isBound => _uid != null;

  bool isFavorite(String productId) => _ids.contains(productId);

  /// Appelé par le ProxyProvider à chaque changement d'utilisateur
  void bindUser(String? uid) {
    if (_started && uid == _uid) return;
    _started = true;
    _uid = uid;
    _sub?.cancel();
    _sub = null;
    _ids = {};

    if (uid == null) {
      _loadLocal();
    } else {
      _startRemote(uid);
    }
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> _loadLocal() async {
    final local = await _service.loadLocal();
    if (_disposed || _uid != null) return;
    _ids = local;
    notifyListeners();
  }

  Future<void> _startRemote(String uid) async {
    try {
      await _service.mergeLocalInto(uid);
    } catch (_) {
      // la fusion sera retentée à la prochaine connexion
    }
    if (_disposed || _uid != uid) return;
    _sub = _service.watch(uid).listen(
      (set) {
        _ids = set;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Ajoute ou retire un favori. Renvoie null si OK, sinon le message d'erreur.
  Future<String?> toggle(String productId) async {
    final uid = _uid;
    final adding = !_ids.contains(productId);
    try {
      if (uid == null) {
        final next = {..._ids};
        adding ? next.add(productId) : next.remove(productId);
        _ids = next;
        await _service.saveLocal(_ids);
        notifyListeners();
      } else if (adding) {
        await _service.add(uid, productId);
      } else {
        await _service.remove(uid, productId);
      }
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