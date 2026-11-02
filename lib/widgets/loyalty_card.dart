import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/loyalty.dart';
import '../utils/shipping.dart';

/// Carte du programme de fidélité : progression et points disponibles
class LoyaltyCard extends StatelessWidget {
  final int orderCount;
  final int points;
  const LoyaltyCard({super.key, required this.orderCount, required this.points});

  @override
  Widget build(BuildContext context) {
    final done = orderCount % kLoyaltyOrdersGoal;
    final left = ordersUntilReward(orderCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lilac,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: AppColors.coral, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Programme de fidélité',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Text('$points pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: done / kLoyaltyOrdersGoal,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            points > 0
                ? 'Vos $points points valent ${dt(pointsToDinars(points))} '
                    'sur votre prochaine commande.'
                : 'Encore $left commande${left > 1 ? 's' : ''} pour gagner '
                    '$kLoyaltyRewardPoints points '
                    '(${dt(pointsToDinars(kLoyaltyRewardPoints))} de remise).',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (points > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Prochaine récompense : $done/$kLoyaltyOrdersGoal commandes.',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}