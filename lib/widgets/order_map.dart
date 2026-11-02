import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/tracking_controller.dart';
import '../models/courier_position.dart';
import '../theme/app_theme.dart';
import 'map_link_button.dart';

/// Carte d'une commande : destination et position du livreur en direct
class OrderMap extends StatefulWidget {
  final String orderId;
  final LatLng? destination;
  final bool followCourier; // true quand la commande est expédiée ou en cours
  const OrderMap({
    super.key,
    required this.orderId,
    required this.destination,
    required this.followCourier,
  });

  @override
  State<OrderMap> createState() => _OrderMapState();
}

class _OrderMapState extends State<OrderMap> {
  final MapController _map = MapController();
  late final Stream<CourierPosition?> _stream;
  Timer? _tick;
  LatLng? _lastCourier;

  @override
  void initState() {
    super.initState();
    _stream = widget.followCourier
        ? context.read<TrackingController>().watchCourier(widget.orderId)
        : Stream<CourierPosition?>.value(null);
    // rafraîchit le texte « il y a X s » toutes les 15 secondes
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _map.dispose();
    super.dispose();
  }

  /// Recadre la carte sur le livreur (et la destination) quand il bouge
  void _refit(LatLng? dest, LatLng? courier) {
    if (courier == null || courier == _lastCourier) return;
    try {
      if (dest != null) {
        _map.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([courier, dest]),
          padding: const EdgeInsets.all(56),
          maxZoom: 16,
        ));
      } else {
        _map.move(courier, 15);
      }
      _lastCourier = courier;
    } catch (_) {
      // la carte n'est pas encore prête : nouvel essai au prochain rafraîchissement
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CourierPosition?>(
      stream: _stream,
      builder: (context, snap) {
        final courier = snap.data;
        final courierPoint =
            courier == null ? null : LatLng(courier.lat, courier.lng);
        final dest = widget.destination;
        final center = courierPoint ?? dest;

        if (center == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lilac,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Le livreur n\'a pas encore partagé sa position.'),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _refit(dest, courierPoint));

        final String status;
        if (!widget.followCourier) {
          status = 'La position du livreur s\'affichera quand la commande '
              'sera expédiée.';
        } else if (courier == null) {
          status = 'Le livreur n\'a pas encore partagé sa position.';
        } else {
          status = 'Position du livreur mise à jour ${courier.ago}.';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 14,
                        // pas de glissement : la page reste défilable
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.ecommerce_app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (dest != null)
                              Marker(
                                point: dest,
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: const Icon(Icons.location_on,
                                    color: AppColors.harissa, size: 40),
                              ),
                            if (courierPoint != null)
                              Marker(
                                point: courierPoint,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.coral,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.local_shipping,
                                      size: 20, color: AppColors.ink),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const Positioned(
                      right: 8,
                      bottom: 6,
                      child: ColoredBox(
                        color: Colors.white70,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('© OpenStreetMap',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.ink)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.harissa),
                const Text(' Destination   ',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const Icon(Icons.local_shipping,
                    size: 16, color: AppColors.coral),
                const Text(' Livreur',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 4),
            Text(status,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            if (dest != null) ...[
              const SizedBox(height: 10),
              MapLinkButton(
                lat: dest.latitude,
                lng: dest.longitude,
                label: 'Ouvrir la destination dans Maps',
              ),
            ],
          ],
        );
      },
    );
  }
}