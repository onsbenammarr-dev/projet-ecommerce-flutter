import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/shipping.dart';
import '../widgets/app_footer.dart';
import '../widgets/footer_view.dart';
import '../widgets/free_shipping_bar.dart';
import 'checkout_view.dart';
import 'product_form_view.dart';

class _Line {
  final ProductModel product;
  final int quantity;
  _Line(this.product, this.quantity);
  double get subtotal => product.price * quantity;
}

class CartView extends StatelessWidget {
  const CartView({super.key});

  /// Message temporaire (2 s), avec une action « Annuler » optionnelle
  void _snack(BuildContext context, String? msg, {VoidCallback? undo}) {
    if (msg == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(msg),
      duration: Duration(seconds: undo != null ? 4 : 2),
      persist: false,
      behavior: SnackBarBehavior.floating,
      action: undo == null
          ? null
          : SnackBarAction(label: 'Annuler', onPressed: undo),
    ));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Tous les articles seront retirés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42), backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await context.read<CartController>().clear();
    if (context.mounted) _snack(context, err ?? 'Panier vidé.');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final pc = context.watch<ProductController>();

    // Associe chaque ligne du panier au produit du catalogue
    final lines = <_Line>[];
    for (final item in cart.items) {
      for (final p in pc.allProducts) {
        if (p.id == item.productId) {
          lines.add(_Line(p, item.quantity));
          break;
        }
      }
    }
    lines.sort((a, b) =>
        a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase()));
    final subtotal = lines.fold<double>(0, (s, l) => s + l.subtotal);
    final count = lines.fold<int>(0, (s, l) => s + l.quantity);
    final fee = shippingFor(subtotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (lines.isNotEmpty)
            IconButton(
              tooltip: 'Vider le panier',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _body(context, cart, pc, lines, subtotal)),
          // panier vide : le footer d'informations reste collé en bas
          if (lines.isEmpty && !pc.loading) const AppFooter(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lines.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sumRow(
                      'Sous-total ($count article${count > 1 ? 's' : ''})',
                      dt(subtotal)),
                  _sumRow('Livraison', fee == 0 ? 'Gratuite' : dt(fee),
                      color: fee == 0 ? AppColors.olive : null),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(dt(subtotal + fee),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckoutView())),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Passer la commande'),
                  ),
                ],
              ),
            ),
          const FooterView(current: FooterTab.cart),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted)),
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _body(BuildContext context, CartController cart,
      ProductController pc, List<_Line> lines, double subtotal) {
    if (pc.loading) return const Center(child: CircularProgressIndicator());
    if (cart.error != null) {
      return Center(child: Text(cart.error!, textAlign: TextAlign.center));
    }
    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 80, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text('Votre panier est vide',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  'Livraison offerte dès ${dt(kFreeShippingThreshold)} d\'achats.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Continuer mes achats'),
              ),
            ],
          ),
        ),
      );
    }

    // index 0 : barre de livraison, 1..n : lignes, dernier : footer
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: lines.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == 0) return FreeShippingBar(subtotal: subtotal);
        if (i == lines.length + 1) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: AppFooter(inset: true),
          );
        }
        final l = lines[i - 1];
        final p = l.product;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ProductImage(product: p),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(dt(p.price),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      if (l.quantity >= p.stock)
                        const Text('Stock maximum atteint',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.harissa)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Diminuer',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              final err =
                                  await cart.setQuantity(p, l.quantity - 1);
                              if (ctx.mounted) _snack(ctx, err);
                            },
                          ),
                          Text('${l.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Augmenter',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: l.quantity >= p.stock
                                ? null
                                : () async {
                                    final err = await cart.setQuantity(
                                        p, l.quantity + 1);
                                    if (ctx.mounted) _snack(ctx, err);
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final qty = l.quantity;
                        final err = await cart.remove(p.id);
                        if (!ctx.mounted) return;
                        if (err != null) {
                          _snack(ctx, err);
                          return;
                        }
                        _snack(ctx, '${p.name} retiré du panier',
                            undo: () => cart.setQuantity(p, qty));
                      },
                    ),
                    Text(dt(l.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}