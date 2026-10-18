/// Règles de livraison : à modifier ici uniquement
const double kShippingFee = 8.0;
const double kFreeShippingThreshold = 100.0;
const String kDeliveryEstimate = '2 à 4 jours ouvrables';

/// Frais de livraison pour un sous-total donné
double shippingFor(double subtotal) =>
    subtotal >= kFreeShippingThreshold ? 0.0 : kShippingFee;

/// Montant restant à ajouter pour obtenir la livraison gratuite
double remainingForFreeShipping(double subtotal) =>
    (kFreeShippingThreshold - subtotal).clamp(0.0, kFreeShippingThreshold).toDouble();

/// Affichage d'un montant : 12.50 DT
String dt(double v) => '${v.toStringAsFixed(2)} DT';

const List<String> kGovernorates = [
  'Ariana', 'Béja', 'Ben Arous', 'Bizerte', 'Gabès', 'Gafsa', 'Jendouba',
  'Kairouan', 'Kasserine', 'Kébili', 'Le Kef', 'Mahdia', 'La Manouba',
  'Médenine', 'Monastir', 'Nabeul', 'Sfax', 'Sidi Bouzid', 'Siliana',
  'Sousse', 'Tataouine', 'Tozeur', 'Tunis', 'Zaghouan',
];