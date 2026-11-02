import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tracking_controller.dart';
import '../theme/app_theme.dart';

/// Bouton « Partager ma position » : à placer dans le détail d'une commande
/// de l'espace livreur, avec l'identifiant de la commande.
class ShareLocationButton extends StatelessWidget {
  final String orderId;
  const ShareLocationButton({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TrackingController>();
    final sharing = t.isSharing(orderId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: sharing
              ? FilledButton.styleFrom(backgroundColor: AppColors.harissa)
              : null,
          onPressed: t.starting
              ? null
              : () => sharing
                  ? context.read<TrackingController>().stop()
                  : context.read<TrackingController>().start(orderId),
          icon: t.starting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(sharing ? Icons.stop_circle_outlined : Icons.my_location),
          label: Text(sharing
              ? 'Arrêter le partage de position'
              : 'Partager ma position'),
        ),
        if (sharing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Votre position est envoyée au client. Gardez l\'application '
              'ouverte pendant la livraison.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        if (t.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.error!,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.harissa)),
          ),
      ],
    );
  }
}