import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cart_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/app_footer.dart';
import '../widgets/footer_view.dart';
import 'login_view.dart';
import 'product_detail_view.dart';
import 'product_form_view.dart';

/// Ajoute ou retire un favori, avec un message temporaire (2 s)
Future<void> toggleFavorite(BuildContext context, String productId) async {
  final fav = context.read<FavoritesController>();
  final adding = !fav.isFavorite(productId);
  final guest = !fav.isBound;
  final err = await fav.toggle(productId);
  if (!context.mounted) return;

  final String msg;
  if (err != null) {
    msg = err;
  } else if (!adding) {
    msg = 'Retiré des favoris';
  } else if (guest) {
    msg = 'Ajouté aux favoris (sur cet appareil). '
        'Connectez-vous pour les garder sur votre compte.';
  } else {
    msg = 'Ajouté aux favoris';
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(msg),
    duration: Duration(seconds: guest && adding ? 3 : 2),
    persist: false,
    behavior: SnackBarBehavior.floating,
  ));
}

/// Bouton cœur réutilisable : [filled] pour les cartes, [outlined] pour la page produit
class FavoriteButton extends StatelessWidget {
  final String productId;
  final bool filled;
  final bool outlined;
  const FavoriteButton({
    super.key,
    required this.productId,
    this.filled = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<FavoritesController>().isFavorite(productId);
    final icon = Icon(
      isFav ? Icons.favorite : Icons.favorite_border,
      color: isFav ? Colors.red : null,
      size: filled ? 20 : null,
    );
    final tooltip = isFav ? 'Retirer des favoris' : 'Ajouter aux favoris';
    void onTap() => toggleFavorite(context, productId);

    if (filled) {
      return IconButton.filledTonal(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2B2A4C),
        ),
        onPressed: onTap,
        icon: icon,
      );
    }
    if (outlined) {
      return IconButton.outlined(
          tooltip: tooltip, onPressed: onTap, icon: icon);
    }
    return IconButton(tooltip: tooltip, onPressed: onTap, icon: icon);
  }
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  Future<void> _addToCart(BuildContext context, ProductModel p) async {
    if (!requireLogin(context, action: 'ajouter ce produit au panier')) return;
    final err = await context.read<CartController>().add(p);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? '${p.name} ajouté au panier'),
      duration: const Duration(seconds: 2),
      persist: false,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesController>();
    final pc = context.watch<ProductController>();

    final items = pc.allProducts.where((p) => fav.ids.contains(p.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      bottomNavigationBar: const FooterView(current: FooterTab.favorites),
      body: Column(
        children: [
          if (!fav.isBound)
            MaterialBanner(
              content: const Text('Vos favoris sont enregistrés sur cet '
                  'appareil. Connectez-vous pour les retrouver partout.'),
              leading: const Icon(Icons.info_outline),
              actions: [
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginView())),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          Expanded(child: _body(context, pc, items)),
        ],
      ),
    );
  }

  Widget _body(
      BuildContext context, ProductController pc, List<ProductModel> items) {
    if (pc.loading) return const Center(child: CircularProgressIndicator());

    if (items.isEmpty) {
      // liste vide : le footer d'informations reste collé en bas
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 80, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('Aucun favori pour le moment',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                        'Touchez le cœur d\'un produit pour le retrouver ici.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 48)),
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Parcourir les produits'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(showFavoritesLink: false),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length + 1, // +1 : le footer d'informations
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == items.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: AppFooter(inset: true, showFavoritesLink: false),
          );
        }
        final p = items[i];
        final inStock = p.stock > 0;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => ProductDetailView(product: p))),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${p.price.toStringAsFixed(2)} DT',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(inStock ? 'En stock' : 'Rupture de stock',
                            style: TextStyle(
                                fontSize: 12,
                                color: inStock
                                    ? Colors.green[700]
                                    : Colors.red)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      FavoriteButton(productId: p.id),
                      IconButton(
                        tooltip: 'Ajouter au panier',
                        onPressed: inStock ? () => _addToCart(ctx, p) : null,
                        icon: const Icon(Icons.add_shopping_cart),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}