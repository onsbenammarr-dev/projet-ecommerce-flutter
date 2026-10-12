import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'product_form_view.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  void _openForm(BuildContext context, [ProductModel? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormView(product: product)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text('« ${p.name} » sera supprimé définitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40), backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await context.read<ProductController>().deleteProduct(p.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? 'Produit supprimé.')));
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<ProductController>();
    final products = [...pc.allProducts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Admin'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
      ),
      body: _body(context, pc, products),
    );
  }

  Widget _body(
      BuildContext context, ProductController pc, List<ProductModel> products) {
    if (pc.loading) return const Center(child: CircularProgressIndicator());
    if (pc.error != null) {
      return Center(child: Text(pc.error!, textAlign: TextAlign.center));
    }
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aucun produit pour le moment.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final err = await context.read<ProductController>().seedDemo();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ?? 'Produits de démo ajoutés.')));
              },
              child: const Text('Charger des produits de démo'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = products[i];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ProductImage(product: p),
              ),
            ),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                '${p.category} • ${p.price.toStringAsFixed(2)} DT • Stock : ${p.stock}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openForm(context, p),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}