import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../theme/app_theme.dart';
import '../views/cart_view.dart';
import '../views/favorites_view.dart';
import '../views/login_view.dart';
import '../views/profile_view.dart';

/// Page active dans la barre (none = aucune, ex. page produit)
enum FooterTab { home, favorites, cart, profile, none }

/// Barre de navigation fixe en bas de l'écran
class FooterView extends StatelessWidget {
  final FooterTab current;
  const FooterView({super.key, required this.current});

  void _go(BuildContext context, FooterTab tab, bool loggedIn) {
    if (tab == current) return;
    final nav = Navigator.of(context);

    if (tab == FooterTab.home) {
      nav.popUntil((r) => r.isFirst);
      return;
    }
    if (tab == FooterTab.cart &&
        !requireLogin(context, action: 'consulter votre panier')) {
      return;
    }

    final Widget page = switch (tab) {
      FooterTab.favorites => const FavoritesView(),
      FooterTab.cart => const CartView(),
      _ => loggedIn ? const ProfileView() : const LoginView(),
    };
    final route = MaterialPageRoute<void>(builder: (_) => page);

    // depuis l'accueil on empile, sinon on remplace la page actuelle
    if (current == FooterTab.home) {
      nav.push(route);
    } else {
      nav.pushReplacement(route);
    }
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final color = active ? AppColors.coral : Colors.white;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: AppColors.coral,
                  textColor: AppColors.ink,
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
    final loggedIn = context.watch<AuthController>().firebaseUser != null;
    final cartCount = context.watch<CartController>().totalQuantity;

    return Material(
      color: AppColors.ink,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _item(
              icon: Icons.home_rounded,
              label: 'Accueil',
              active: current == FooterTab.home,
              onTap: () => _go(context, FooterTab.home, loggedIn),
            ),
            _item(
              icon: Icons.favorite_border_rounded,
              label: 'Favoris',
              active: current == FooterTab.favorites,
              onTap: () => _go(context, FooterTab.favorites, loggedIn),
            ),
            _item(
              icon: Icons.shopping_bag_outlined,
              label: 'Panier',
              active: current == FooterTab.cart,
              badge: loggedIn ? cartCount : 0,
              onTap: () => _go(context, FooterTab.cart, loggedIn),
            ),
            _item(
              icon: Icons.person_outline_rounded,
              label: loggedIn ? 'Profil' : 'Connexion',
              active: current == FooterTab.profile,
              onTap: () => _go(context, FooterTab.profile, loggedIn),
            ),
          ],
        ),
      ),
    );
  }
}