import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/input_formatters.dart';

/// Contrôleurs des champs de la carte (détenus par l'écran de commande)
class CardControllers {
  final number = TextEditingController();
  final holder = TextEditingController();
  final expiry = TextEditingController();
  final cvv = TextEditingController();

  void clear() {
    number.clear();
    holder.clear();
    expiry.clear();
    cvv.clear();
  }

  void dispose() {
    number.dispose();
    holder.dispose();
    expiry.dispose();
    cvv.dispose();
  }
}

/// Choix du moyen de paiement et formulaire de carte
class PaymentSection extends StatelessWidget {
  final String method;
  final ValueChanged<String> onMethodChanged;
  final CardControllers card;

  const PaymentSection({
    super.key,
    required this.method,
    required this.onMethodChanged,
    required this.card,
  });

  Widget _option(String value, IconData icon, String title, String subtitle) {
    final selected = method == value;
    return Semantics(
      selected: selected,
      button: true,
      label: title,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: selected ? AppColors.ink : AppColors.line,
              width: selected ? 1.6 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onMethodChanged(value),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.muted)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _option(kPayCard, Icons.credit_card, 'Carte bancaire',
            'Paiement sécurisé immédiat'),
        const SizedBox(height: 10),
        _option(kPayCash, Icons.payments_outlined, 'Paiement à la livraison',
            'Vous réglez en espèces au livreur'),
        if (method == kPayCard) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: card.number,
            keyboardType: TextInputType.number,
            inputFormatters: [CardNumberFormatter()],
            decoration: const InputDecoration(
              labelText: 'Numéro de carte',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card),
            ),
            validator: (v) => PaymentService.isValidCardNumber(
                    (v ?? '').replaceAll(' ', ''))
                ? null
                : 'Numéro de carte invalide',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: card.holder,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Titulaire de la carte',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Saisissez le nom sur la carte'
                : null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: card.expiry,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ExpiryFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Expiration',
                    hintText: 'MM/AA',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  validator: (v) => PaymentService.isExpiryValid(v ?? '')
                      ? null
                      : 'Date invalide ou expirée',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: card.cvv,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      (v ?? '').length == 3 ? null : '3 chiffres',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lilac,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode démonstration. Carte acceptée : 4242 4242 4242 4242. '
                    'Carte refusée : 4000 0000 0000 0002. N\'utilisez jamais '
                    'votre vraie carte : aucune donnée bancaire n\'est enregistrée.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}