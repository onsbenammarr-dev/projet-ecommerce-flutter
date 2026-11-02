import 'package:flutter/material.dart';
import '../utils/location_helper.dart';

/// Bouton « Ouvrir dans Maps » : utilisable par le client, l'admin et le livreur
class MapLinkButton extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;
  const MapLinkButton({
    super.key,
    required this.lat,
    required this.lng,
    this.label = 'Ouvrir dans Maps',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
      onPressed: () async {
        final ok = await openInMaps(lat, lng);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible d\'ouvrir la carte.')));
        }
      },
      icon: const Icon(Icons.map_outlined),
      label: Text(label),
    );
  }
}