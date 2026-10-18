
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../utils/shipping.dart';
import '../widgets/app_footer.dart';
import '../widgets/footer_view.dart';
import 'orders_view.dart';

class OrderSuccessView extends StatelessWidget {
  final OrderModel order;
  const OrderSuccessView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ship = order.shipping;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Commande'),
      ),
      bottomNavigationBar: const FooterView(current: FooterTab.none),
      body: SafeArea(
        child: FooterScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.olive,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Commande enregistrée',
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Référence #${order.shortId}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final i in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${i.quantity} × ${i.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(dt(i.subtotal)),
                            ],
                          ),
                        ),
                      const Divider(height: 24),
                      _amount('Sous-total', dt(order.subtotal)),
                      _amount(
                        'Livraison',
                        order.shippingFee == 0
                            ? 'Gratuite'
                            : dt(order.shippingFee),
                        color: order.shippingFee == 0
                            ? AppColors.olive
                            : null,
                      ),
                      const Divider(height: 24),
                      _amount('Total', dt(order.total), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _info(
                        Icons.event_outlined,
                        'Date',
                        order.dateLabel,
                      ),
                      _info(
                        Icons.hourglass_empty_rounded,
                        'Statut',
                        order.statusLabel,
                      ),
                      if (ship != null) ...[
                        _info(
                          Icons.person_outline,
                          'Destinataire',
                          ship.fullName,
                        ),
                        _info(
                          Icons.phone_outlined,
                          'Téléphone',
                          '+216 ${ship.phone}',
                        ),
                      ],
                      _info(
                        Icons.location_on_outlined,
                        'Livraison à',
                        order.address,
                      ),
                      _info(
                        Icons.local_shipping_outlined,
                        'Délai estimé',
                        kDeliveryEstimate,
                      ),
                      if (ship != null && ship.note.isNotEmpty)
                        _info(
                          Icons.edit_note_rounded,
                          'Instructions',
                          ship.note,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Retour à l\'accueil'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrdersView(),
                  ),
                ),
                child: const Text('Voir mes commandes'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amount(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? null : AppColors.muted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 17 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              '$label : ',
              style: const TextStyle(color: AppColors.muted),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
