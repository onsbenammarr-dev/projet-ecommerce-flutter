import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/courier_position.dart';
import '../services/tracking_service.dart';
import '../utils/location_helper.dart';

class TrackingController extends ChangeNotifier {
  final TrackingService _service = TrackingService();
  StreamSubscription<Position>? _sub;

  String? activeOrderId;
  bool starting = false;
  String? error;

  bool isSharing(String orderId) => activeOrderId == orderId;

  /// Côté client : position du livreur en direct
  Stream<CourierPosition?> watchCourier(String orderId) =>
      _service.watch(orderId);

  /// Côté livreur : démarre le partage de position pour une commande
  Future<void> start(String orderId) async {
    starting = true;
    error = null;
    notifyListeners();
    try {
      final first = await getCurrentPosition();
      await _sub?.cancel();
      await _service.publish(orderId, first.latitude, first.longitude);
      activeOrderId = orderId;

      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (p) => _service
            .publish(orderId, p.latitude, p.longitude)
            .catchError((_) {}),
        onError: (_) {
          error = 'Position indisponible.';
          notifyListeners();
        },
      );
    } on LocationException catch (e) {
      error = e.message;
    } on TimeoutException {
      error = 'Position introuvable. Sortez à l\'air libre et réessayez.';
    } catch (_) {
      error = 'Impossible de démarrer le partage '
          '(cette commande vous est-elle bien assignée ?).';
    }
    starting = false;
    notifyListeners();
  }

  /// Côté livreur : arrête le partage et efface la position
  Future<void> stop() async {
    final id = activeOrderId;
    await _sub?.cancel();
    _sub = null;
    activeOrderId = null;
    error = null;
    notifyListeners();
    if (id != null) {
      try {
        await _service.clear(id);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
