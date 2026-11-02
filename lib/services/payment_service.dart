import 'dart:math';

/// Moyens de paiement (valeurs enregistrées dans la commande)
const String kPayCard = 'carte';
const String kPayCash = 'livraison';

class PaymentResult {
  final bool approved;
  final String? reference;
  final String? message;

  const PaymentResult._(this.approved, this.reference, this.message);
  const PaymentResult.approved(String reference) : this._(true, reference, null);
  const PaymentResult.refused(String message) : this._(false, null, message);
}

/// SIMULATION d'une passerelle de paiement (acteur « Système de paiement »).
/// Aucune donnée de carte n'est conservée ni envoyée ailleurs.
///
/// Cartes de test :
///   4242 4242 4242 4242 -> acceptée
///   4000 0000 0000 0002 -> fonds insuffisants
///   4000 0000 0000 0069 -> carte expirée
///   4000 0000 0000 0127 -> code de sécurité incorrect
class PaymentService {
  Future<PaymentResult> chargeCard({
    required double amount,
    required String cardNumber,
    required String expiry,
    required String cvv,
  }) async {
    // délai de traitement simulé
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (!isValidCardNumber(digits)) {
      return const PaymentResult.refused('Numéro de carte invalide.');
    }
    switch (digits) {
      case '4000000000000002':
        return const PaymentResult.refused('Fonds insuffisants.');
      case '4000000000000069':
        return const PaymentResult.refused('Carte expirée.');
      case '4000000000000127':
        return const PaymentResult.refused('Code de sécurité incorrect.');
    }
    return PaymentResult.approved(_reference());
  }

  /// Annule un paiement accepté (si la commande n'a pas pu être enregistrée)
  Future<void> refund(String reference) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  /// Contrôle de Luhn : détecte les numéros de carte mal saisis
  static bool isValidCardNumber(String digits) {
    if (!RegExp(r'^\d{13,19}$').hasMatch(digits)) return false;
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Date MM/AA valide et non dépassée
  static bool isExpiryValid(String value) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value.trim());
    if (m == null) return false;
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return false;
    return DateTime(year, month + 1, 1).isAfter(DateTime.now());
  }

  String _reference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return 'SIM-${List.generate(8, (_) => chars[r.nextInt(chars.length)]).join()}';
  }
}