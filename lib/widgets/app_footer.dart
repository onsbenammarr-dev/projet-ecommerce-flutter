import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../views/favorites_view.dart';
import 'brand_mark.dart';

// À remplacer par vos vraies coordonnées
const String kContactEmail = 'contact@votre-domaine.tn';
const String kContactPhone = '+216 00 000 000';

/// Remplace SingleChildScrollView : le contenu défile et le footer reste
/// collé en bas de l'écran quand la page est courte.
class FooterScroll extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FooterScroll({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              Padding(padding: padding, child: child),
              const Spacer(),
              const SizedBox(height: 24),
              const AppFooter(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pied de page : présentation, aide, contact, copyright
class AppFooter extends StatelessWidget {
  /// true : coins arrondis partout (à utiliser dans une liste avec marges)
  final bool inset;
  final bool showFavoritesLink;
  const AppFooter({
    super.key,
    this.inset = false,
    this.showFavoritesLink = true,
  });

  void _info(BuildContext context, String title, String text) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(text, style: const TextStyle(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x55FFFFFF)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      );

  Widget _contact(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.coral),
            const SizedBox(width: 10),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFFD9D7F0), fontSize: 13.5)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: inset
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(size: 32, textColor: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Votre marché en ligne : parcourez le catalogue, '
            'commandez et suivez votre livraison.',
            style: TextStyle(color: Color(0xFFD9D7F0), height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (showFavoritesLink)
                _link(
                  'Mes favoris',
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FavoritesView())),
                ),
              _link(
                'Livraison',
                () => _info(
                    context,
                    'Livraison',
                    'Vos commandes sont confiées à nos sociétés de livraison '
                        'partenaires. Vous suivez l\'état de chaque commande '
                        'depuis votre historique.'),
              ),
              _link(
                'Paiement',
                () => _info(
                    context,
                    'Paiement',
                    'Le paiement est traité par un système de paiement '
                        'sécurisé. Aucune donnée bancaire n\'est conservée '
                        'dans l\'application.'),
              ),
              _link(
                'Fidélité',
                () => _info(
                    context,
                    'Programme de fidélité',
                    'Dès votre 3e commande validée, vous gagnez des points '
                        'de fidélité. Ils sont déduits du total de votre '
                        'commande suivante.'),
              ),
              _link(
                'À propos',
                () => _info(
                    context,
                    'À propos de $kAppName',
                    '$kAppName est une boutique en ligne : le catalogue est '
                        'ouvert à tous, la connexion est demandée pour '
                        'commander.'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _contact(Icons.mail_outline_rounded, kContactEmail),
          _contact(Icons.phone_outlined, kContactPhone),
          _contact(Icons.place_outlined, 'Tunisie'),
          const SizedBox(height: 14),
          const Divider(color: Color(0x33FFFFFF)),
          const SizedBox(height: 12),
          const Text('© 2026 $kAppName. Tous droits réservés.',
              style: TextStyle(color: Color(0xFFB8B6D9), fontSize: 12)),
        ],
      ),
    );
  }
}