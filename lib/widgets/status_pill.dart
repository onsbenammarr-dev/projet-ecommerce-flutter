import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastille de statut
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(16)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      );
}

Color orderStatusColor(String status) => switch (status) {
      'confirmee' => AppColors.mint,
      'annulee' => const Color(0xFFFBE4E2),
      _ => AppColors.peach,
    };

Color deliveryStatusColor(String status) => switch (status) {
      'livree' => AppColors.mint,
      'en_cours' => AppColors.sky,
      'expediee' => AppColors.lilac,
      _ => AppColors.peach,
    };

String paymentLabel(String status) => switch (status) {
      'paye' => 'Payé',
      'refuse' => 'Refusé',
      _ => 'En attente',
    };
    String paymentMethodLabel(String method) => switch (method) {
      'carte' => 'Carte bancaire',
      'livraison' => 'À la livraison',
      _ => 'Non précisé',
    };