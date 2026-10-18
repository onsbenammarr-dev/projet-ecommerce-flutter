import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../utils/shipping.dart';
import '../widgets/footer_view.dart';
import '../widgets/status_pill.dart';
import 'order_detail_view.dart';

/// Historique des commandes du client
class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  late final Stream<List<OrderModel>> _stream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthController>().firebaseUser?.uid;
    _stream = uid == null
        ? Stream.value(<OrderModel>[])
        : context.read<OrderController>().watchByUser(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      bottomNavigationBar: const FooterView(current: FooterTab.profile),
      body: StreamBuilder<List<OrderModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger vos commandes.\n'
                  'Vérifiez votre connexion puis réessayez.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 80, color: AppColors.muted),
                    const SizedBox(height: 16),
                    Text('Aucune commande',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Vos commandes apparaîtront ici.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 48)),
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Découvrir les produits'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final o = orders[i];
              final count = o.items.fold<int>(0, (s, e) => s + e.quantity);
              final cancelled = o.status == 'annulee';
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => OrderDetailView(orderId: o.id)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Commande #${o.shortId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                color: AppColors.muted),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(o.dateLabel,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusPill(o.statusLabel,
                                orderStatusColor(o.status)),
                            if (!cancelled)
                              StatusPill(o.deliveryLabel,
                                  deliveryStatusColor(o.deliveryStatus)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('$count article${count > 1 ? 's' : ''}',
                                style:
                                    const TextStyle(color: AppColors.muted)),
                            const Spacer(),
                            Text(dt(o.total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}