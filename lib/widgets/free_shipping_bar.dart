import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/shipping.dart';

/// Barre « Plus que X DT pour la livraison gratuite »
class FreeShippingBar extends StatelessWidget {
  final double subtotal;
  const FreeShippingBar({super.key, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final free = subtotal >= kFreeShippingThreshold;
    final progress =
        (subtotal / kFreeShippingThreshold).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: free ? AppColors.mint : AppColors.lilac,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                free ? Icons.check_circle_rounded : Icons.local_shipping_outlined,
                size: 22,
                color: free ? AppColors.olive : AppColors.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  free
                      ? 'Livraison offerte sur cette commande !'
                      : 'Plus que ${dt(remainingForFreeShipping(subtotal))} '
                          'pour la livraison gratuite',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: free ? AppColors.olive : AppColors.coral,
            ),
          ),
          if (!free) ...[
            const SizedBox(height: 6),
            Text(
              'Livraison ${dt(kShippingFee)}, offerte dès ${dt(kFreeShippingThreshold)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}