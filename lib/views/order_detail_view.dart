import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../utils/shipping.dart';
import '../widgets/app_footer.dart';
import '../widgets/footer_view.dart';
import '../widgets/status_pill.dart';

/// Détail d'une commande, avec la frise de suivi de livraison (en direct)
class OrderDetailView extends StatefulWidget {
  final String orderId;
  const OrderDetailView({super.key, required this.orderId});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  late final Stream<List<OrderModel>> _stream;

  // étape, libellé, description
  static const _steps = <(String, String, String)>[
    ('en_preparation', 'En préparation', 'Votre commande est en cours de préparation'),
    ('expediee', 'Expédiée', 'Votre colis a été confié au transporteur'),
    ('en_cours', 'En cours de livraison', 'Le livreur est en route vers vous'),
    ('livree', 'Livrée', 'Votre commande a été remise'),
  ];

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthController>().firebaseUser?.uid;
    _stream = uid == null
        ? Stream.value(<OrderModel>[])
        : context.read<OrderController>().watchByUser(uid);
  }

  Widget _timeline(OrderModel o) {
    var current = _steps.indexWhere((s) => s.$1 == o.deliveryStatus);
    if (current < 0) current = 0;
    final delivered = o.deliveryStatus == 'livree';

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          Builder(builder: (context) {
            final done = i < current || (i == current && delivered);
            final active = i == current && !delivered;
            final last = i == _steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.ink
                            : active
                                ? AppColors.coral
                                : Colors.white,
                        border: Border.all(
                            color: done || active
                                ? Colors.transparent
                                : AppColors.line,
                            width: 2),
                      ),
                      child: done
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : active
                              ? const Icon(Icons.circle,
                                  size: 10, color: AppColors.ink)
                              : null,
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 38,
                        color: i < current ? AppColors.ink : AppColors.line,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_steps[i].$2,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: done || active
                                    ? AppColors.ink
                                    : AppColors.muted)),
                        if (active || (done && last))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(_steps[i].$3,
                                style: const TextStyle(
                                    fontSize: 12.5, color: AppColors.muted)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _info(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Text('$label : ', style: const TextStyle(color: AppColors.muted)),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _amount(String label, String value,
          {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: bold ? null : AppColors.muted,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 17 : null)),
          ],
        ),
      );

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: _stream,
      builder: (context, snap) {
        final matches =
            (snap.data ?? []).where((o) => o.id == widget.orderId).toList();
        final o = matches.isEmpty ? null : matches.first;

        return Scaffold(
          appBar: AppBar(
              title: Text(o == null ? 'Commande' : 'Commande #${o.shortId}')),
          bottomNavigationBar: const FooterView(current: FooterTab.profile),
          body: o == null
              ? Center(
                  child: snap.hasError
                      ? const Text('Impossible de charger la commande.')
                      : snap.connectionState == ConnectionState.waiting
                          ? const CircularProgressIndicator()
                          : const Text('Commande introuvable.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                    Row(
                      children: [
                        StatusPill(o.statusLabel, orderStatusColor(o.status)),
                        const Spacer(),
                        Text(o.dateLabel,
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Suivi de livraison
                    _title('Suivi de livraison'),
                    if (o.status == 'annulee')
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE4E2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel_outlined,
                                color: AppColors.harissa),
                            SizedBox(width: 10),
                            Expanded(
                                child: Text('Cette commande a été annulée.')),
                          ],
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _timeline(o),
                        ),
                      ),
                    const SizedBox(height: 22),

                    // Articles et montants
                    _title('Articles'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final i in o.items)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text('${i.quantity} × ${i.name}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                    Text(dt(i.subtotal)),
                                  ],
                                ),
                              ),
                            const Divider(height: 24),
                            _amount('Sous-total', dt(o.subtotal)),
                            _amount(
                              'Livraison',
                              o.shippingFee == 0
                                  ? 'Gratuite'
                                  : dt(o.shippingFee),
                              color:
                                  o.shippingFee == 0 ? AppColors.olive : null,
                            ),
                            const Divider(height: 24),
                            _amount('Total', dt(o.total), bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Livraison et paiement
                    _title('Informations'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (o.shipping != null) ...[
                              _info(Icons.person_outline, 'Destinataire',
                                  o.shipping!.fullName),
                              _info(Icons.phone_outlined, 'Téléphone',
                                  '+216 ${o.shipping!.phone}'),
                            ],
                            _info(Icons.location_on_outlined, 'Adresse',
                                o.address),
                            if (o.shipping != null &&
                                o.shipping!.note.isNotEmpty)
                              _info(Icons.edit_note_rounded, 'Instructions',
                                  o.shipping!.note),
                            _info(Icons.local_shipping_outlined,
                                'Délai estimé', kDeliveryEstimate),
                            _info(Icons.payments_outlined, 'Paiement',
                                paymentLabel(o.paymentStatus)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AppFooter(inset: true),
                    const SizedBox(height: 16),
                  ],
                ),
        );
      },
    );
  }
}