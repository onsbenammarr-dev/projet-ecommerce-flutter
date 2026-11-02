import 'shipping.dart';

/// Programme de fidélité : à modifier ici uniquement
/// (si vous changez ces valeurs, changez aussi les règles Firestore)
const int kLoyaltyOrdersGoal = 3; // commandes pour gagner une récompense
const int kLoyaltyRewardPoints = 100; // points gagnés
const int kPointsPerDinar = 10; // 10 points = 1 DT

class LoyaltyUse {
  final int pointsUsed;
  final double discount;
  const LoyaltyUse(this.pointsUsed, this.discount);
}

/// Remise obtenue avec les points. Le total après remise garde au moins 1 DT.
LoyaltyUse applyLoyalty({
  required double subtotal,
  required int points,
  required bool use,
}) {
  if (!use || points <= 0) return const LoyaltyUse(0, 0);
  final maxPoints = ((subtotal - 1) * kPointsPerDinar).floor();
  if (maxPoints <= 0) return const LoyaltyUse(0, 0);
  final used = points < maxPoints ? points : maxPoints;
  return LoyaltyUse(used, used / kPointsPerDinar);
}

/// Points gagnés par la commande qui porte le compteur à [newOrderCount]
int pointsEarnedFor(int newOrderCount) =>
    newOrderCount % kLoyaltyOrdersGoal == 0 ? kLoyaltyRewardPoints : 0;

/// Commandes restantes avant la prochaine récompense
int ordersUntilReward(int orderCount) =>
    kLoyaltyOrdersGoal - (orderCount % kLoyaltyOrdersGoal);

double pointsToDinars(int points) => points / kPointsPerDinar;

String dinars(double v) => dt(v);