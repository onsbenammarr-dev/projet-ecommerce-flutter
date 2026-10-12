import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import '../widgets/brand_mark.dart';
import '../widgets/footer_view.dart';
import 'login_view.dart';
import 'product_detail_view.dart';
import 'product_form_view.dart';
import 'favorites_view.dart';
import 'profile_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void _openFilters(BuildContext context) {
    final pc = context.read<ProductController>();
    final max = pc.maxPrice;
    final current = pc.priceFilter;
    var range = RangeValues(
      (current?.start ?? 0).clamp(0, max).toDouble(),
      (current?.end ?? max).clamp(0, max).toDouble(),
    );
    var sort = pc.sort;

    const sorts = {
      SortOption.popularity: 'Popularité',
      SortOption.priceAsc: 'Prix croissant',
      SortOption.priceDesc: 'Prix décroissant',
    };

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trier par',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in sorts.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: sort == e.key,
                        showCheckmark: false,
                        selectedColor: AppColors.ink,
                        backgroundColor: AppColors.bg,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                sort == e.key ? Colors.white : AppColors.ink),
                        onSelected: (_) => setState(() => sort = e.key),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Prix',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${range.start.round()} DT  à  ${range.end.round()} DT',
                    style: const TextStyle(color: AppColors.muted)),
                RangeSlider(
                  values: range,
                  min: 0,
                  max: max,
                  divisions: max.round().clamp(1, 200),
                  activeColor: AppColors.ink,
                  inactiveColor: AppColors.line,
                  onChanged: (v) => setState(() => range = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                        onPressed: () {
                          pc.setPriceFilter(null);
                          pc.setSort(SortOption.popularity);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          pc.setSort(sort);
                          final full = range.start <= 0 && range.end >= max;
                          pc.setPriceFilter(full ? null : range);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
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
    final auth = context.watch<AuthController>();
    final pc = context.watch<ProductController>();
    final products = pc.products;
    final loggedIn = auth.firebaseUser != null;
    final filterActive = pc.hasPriceFilter || pc.sort != SortOption.popularity;
    final ready = !pc.loading && pc.error == null;

    OutlineInputBorder pill([Color c = Colors.transparent, double w = 0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: c, width: w),
        );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const BrandMark(size: 30),
        actions: [
          if (loggedIn)
            IconButton(
              tooltip: 'Mon profil',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileView())),
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.ink,
                backgroundImage: auth.currentUser?.photoBytes != null
                    ? MemoryImage(auth.currentUser!.photoBytes!)
                    : null,
                child: auth.currentUser?.photoBytes == null
                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                    : null,
              ),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginView())),
              child: const Text('Connexion'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      bottomNavigationBar: const FooterView(current: FooterTab.home),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: pc.setQuery,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: pill(),
                      enabledBorder: pill(),
                      focusedBorder: pill(AppColors.ink, 1.6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Trier et filtrer',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(52, 52),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => _openFilters(context),
                  icon: Badge(
                    isLabelVisible: filterActive,
                    smallSize: 9,
                    backgroundColor: AppColors.coral,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (pc.query.isEmpty)
                  const SliverToBoxAdapter(child: _PromoBanner()),
                SliverToBoxAdapter(child: _Categories(pc: pc)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                    child: Row(
                      children: [
                        Text('Nos produits',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (ready)
                          Text(
                              '${products.length} article${products.length > 1 ? 's' : ''}',
                              style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
                ..._productSlivers(context, pc, products),
                if (ready) const SliverToBoxAdapter(child: AppFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _productSlivers(
      BuildContext context, ProductController pc, List<ProductModel> products) {
    if (pc.loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (pc.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 52, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text(pc.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 46)),
                    onPressed: pc.retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    if (products.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.muted),
                SizedBox(height: 12),
                Text('Aucun produit trouvé'),
                SizedBox(height: 4),
                Text('Essayez un autre mot ou retirez un filtre.',
                    style: TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            childAspectRatio: 0.7,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => _ProductCard(product: products[i]),
            childCount: products.length,
          ),
        ),
      ),
    ];
  }
}

/// Bannière sur la remise de fidélité
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.lilac,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gagnez des points de fidélité',
                    style:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Après 3 commandes, une remise est appliquée sur la suivante.',
                    style: t.bodySmall
                        ?.copyWith(color: AppColors.muted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
                color: AppColors.coral, shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.ink, size: 28),
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  final ProductController pc;
  const _Categories({required this.pc});

  Widget _chip(String label, bool selected, Color tint, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppColors.ink,
          backgroundColor: tint,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink),
          onSelected: (_) => onTap(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cats = pc.categories;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip('Tous', pc.category == null, Colors.white,
              () => pc.setCategory(null)),
          for (var i = 0; i < cats.length; i++)
            _chip(cats[i], pc.category == cats[i],
                AppColors.tints[i % AppColors.tints.length],
                () => pc.setCategory(cats[i])),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;

    return Material(
      color: AppColors.tintFor(product.name),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailView(product: product))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox.expand(
                          child: ProductImage(product: product)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child:
                          FavoriteButton(productId: product.id, filled: true),
                    ),
                    if (soldOut)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Rupture',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, height: 1.2)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('${product.price.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded,
                        size: 15, color: AppColors.coral),
                    const SizedBox(width: 2),
                    Text(product.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}