import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cart_controller.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import '../widgets/footer_view.dart';
import 'cart_view.dart';
import 'favorites_view.dart';
import 'login_view.dart';
import 'product_form_view.dart';

class ProductDetailView extends StatefulWidget {
  final ProductModel product;
  const ProductDetailView({super.key, required this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _qty = 1;
  bool _adding = false;

  ProductModel get product => widget.product;

  void _openCart() {
    if (!requireLogin(context, action: 'consulter votre panier')) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CartView()));
  }

  Future<void> _addToCart() async {
    if (!requireLogin(context, action: 'ajouter ce produit au panier')) return;

    final added = _qty;
    setState(() => _adding = true);
    final err = await context.read<CartController>().add(product, qty: added);
    if (!mounted) return;
    setState(() {
      _adding = false;
      if (err == null) _qty = 1;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? '$added × ${product.name} ajouté au panier'),
      duration: const Duration(seconds: 2),
      persist: false,
      action: err != null
          ? null
          : SnackBarAction(label: 'Voir le panier', onPressed: _openCart),
    ));
  }

  Widget _stockPill(bool inStock) {
    late final Color bg;
    late final Color fg;
    late final String label;
    if (!inStock) {
      bg = const Color(0xFFFBE4E2);
      fg = AppColors.harissa;
      label = 'Rupture de stock';
    } else if (product.stock <= 5) {
      bg = const Color(0xFFFFE9C7);
      fg = const Color(0xFF8A5A00);
      label = 'Plus que ${product.stock} en stock';
    } else {
      bg = const Color(0xFFD7F2E6);
      fg = AppColors.olive;
      label = 'En stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cart = context.watch<CartController>();
    final loggedIn = cart.isBound;
    final inCart = cart.quantityOf(product.id);
    final available = product.stock - inCart;
    final inStock = product.stock > 0;
    final canAdd = inStock && available > 0 && !_adding;
    if (_qty > available && available > 0) _qty = available;

    return Scaffold(
      appBar: AppBar(
        actions: [
          FavoriteButton(productId: product.id),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Image dans un cadre pastel
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tintFor(product.name),
              borderRadius: BorderRadius.circular(36),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SizedBox.expand(child: ProductImage(product: product)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.category,
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(product.name,
                    style: t.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.coral, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      product.ratingCount == 0
                          ? 'Aucun avis'
                          : '${product.ratingAvg.toStringAsFixed(1)}  '
                              '(${product.ratingCount} avis)',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('${product.price.toStringAsFixed(2)} DT',
                        style: t.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    _stockPill(inStock),
                  ],
                ),
                if (loggedIn && inCart > 0) ...[
                  const SizedBox(height: 8),
                  Text('Déjà $inCart dans votre panier',
                      style: const TextStyle(
                          color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 24),
                Text('Description',
                    style:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(product.description,
                    style: t.bodyMedium?.copyWith(
                        height: 1.55, color: const Color(0xFF45446A))),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const AppFooter(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // barre d'achat : quantité + bouton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                if (inStock && available > 0) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Diminuer',
                          onPressed:
                              _qty > 1 ? () => setState(() => _qty--) : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        SizedBox(
                          width: 22,
                          child: Text('$_qty',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        IconButton(
                          tooltip: 'Augmenter',
                          onPressed: _qty < available
                              ? () => setState(() => _qty++)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canAdd ? _addToCart : null,
                    icon: _adding
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(!inStock
                        ? 'Rupture de stock'
                        : available <= 0
                            ? 'Maximum atteint'
                            : 'Ajouter au panier'),
                  ),
                ),
              ],
            ),
          ),
          // barre de navigation (aucun onglet actif sur cette page)
          const FooterView(current: FooterTab.none),
        ],
      ),
    );
  }
}