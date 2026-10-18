import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/product_controller.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/shipping.dart';
import '../widgets/footer_view.dart';
import '../widgets/free_shipping_bar.dart';
import 'order_success_view.dart';
import 'product_form_view.dart';

class _Line {
  final ProductModel product;
  final int quantity;
  _Line(this.product, this.quantity);
  double get subtotal => product.price * quantity;
}

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _phone = TextEditingController();
  final _governorate = TextEditingController();
  final _city = TextEditingController();
  late final TextEditingController _address;
  final _postal = TextEditingController();
  final _note = TextEditingController();

  bool _saveAddress = true;
  bool _terms = false;
  bool _termsError = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _name = TextEditingController(text: user?.name ?? '');
    _address = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _governorate, _city, _address, _postal, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
      persist: false,
    ));
  }

  /// 8 chiffres, sans espaces ni indicatif +216
  String _normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('216') && d.length == 11) d = d.substring(3);
    return d;
  }

  Future<void> _pickGovernorate() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choisissez votre gouvernorat',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: kGovernorates.length,
                itemBuilder: (_, i) {
                  final g = kGovernorates[i];
                  return ListTile(
                    title: Text(g),
                    trailing: g == _governorate.text
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(ctx, g),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _governorate.text = selected);
  }

  void _showTerms() {
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
              Text('Conditions générales de vente',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                'Livraison : frais de ${dt(kShippingFee)}, offerts dès '
                '${dt(kFreeShippingThreshold)} d\'achats. Délai estimé : '
                '$kDeliveryEstimate.\n\n'
                'Prix : affichés en dinars tunisiens (DT), toutes taxes comprises.\n\n'
                'Paiement : traité par un système de paiement sécurisé, aucune '
                'donnée bancaire n\'est conservée.\n\n'
                '(Texte à compléter avec vos conditions de retour et de garantie.)',
                style: const TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(bool stockOk) async {
    final valid = _formKey.currentState!.validate();
    if (!_terms) setState(() => _termsError = true);
    if (!valid || !_terms) {
      _snack('Vérifiez les champs signalés en rouge.');
      return;
    }
    if (!stockOk) return;

    final auth = context.read<AuthController>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;

    final shipping = ShippingInfo(
      fullName: _name.text.trim(),
      phone: _normalizePhone(_phone.text),
      governorate: _governorate.text.trim(),
      city: _city.text.trim(),
      address: _address.text.trim(),
      postalCode: _postal.text.trim(),
      note: _note.text.trim(),
    );

    final orders = context.read<OrderController>();
    final order = await orders.placeOrder(
      uid: uid,
      cart: context.read<CartController>().items,
      shipping: shipping,
    );
    if (!mounted) return;

    if (order == null) {
      _snack(orders.error ?? 'Erreur');
      return;
    }

    // mémorise l'adresse dans le profil (sans bloquer en cas d'échec)
    if (_saveAddress) {
      await auth.updateProfile(
        name: auth.currentUser?.name ?? shipping.fullName,
        address: shipping.formatted,
      );
      if (!mounted) return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderSuccessView(order: order)),
      (route) => route.isFirst,
    );
  }

  Widget _section(int n, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.ink,
              child: Text('$n',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final pc = context.watch<ProductController>();
    final placing = context.watch<OrderController>().isPlacing;

    final lines = <_Line>[];
    for (final item in cart.items) {
      for (final p in pc.allProducts) {
        if (p.id == item.productId) {
          lines.add(_Line(p, item.quantity));
          break;
        }
      }
    }
    final subtotal = lines.fold<double>(0, (s, l) => s + l.subtotal);
    final fee = shippingFor(subtotal);
    final total = subtotal + fee;
    final stockOk = !lines.any((l) => l.quantity > l.product.stock);

    return Scaffold(
      appBar: AppBar(title: const Text('Finaliser la commande')),
      body: pc.loading
          ? const Center(child: CircularProgressIndicator())
          : lines.isEmpty
              ? const Center(child: Text('Votre panier est vide.'))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      FreeShippingBar(subtotal: subtotal),
                      const SizedBox(height: 22),
                      if (!stockOk) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE4E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppColors.harissa),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    'Certains articles ne sont plus disponibles '
                                    'en quantité suffisante. Modifiez votre panier.',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // 1. Contact
                      _section(
                        1,
                        'Vos coordonnées',
                        Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 3)
                                      ? 'Saisissez votre nom complet'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9 +]')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                hintText: '20 123 456',
                                prefixText: '+216  ',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                final d = _normalizePhone(v ?? '');
                                return RegExp(r'^[2-9][0-9]{7}$').hasMatch(d)
                                    ? null
                                    : 'Numéro invalide (8 chiffres)';
                              },
                            ),
                          ],
                        ),
                      ),

                      // 2. Adresse
                      _section(
                        2,
                        'Adresse de livraison',
                        Column(
                          children: [
                            TextFormField(
                              controller: _governorate,
                              readOnly: true,
                              onTap: _pickGovernorate,
                              decoration: const InputDecoration(
                                labelText: 'Gouvernorat',
                                prefixIcon: Icon(Icons.map_outlined),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Choisissez un gouvernorat'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _city,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Ville / délégation',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Saisissez votre ville'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _address,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Adresse',
                                hintText: 'N°, rue, immeuble, étage',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 6)
                                      ? 'Saisissez une adresse complète'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _postal,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Code postal',
                                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                              ),
                              validator: (v) => (v ?? '').length == 4
                                  ? null
                                  : 'Code postal à 4 chiffres',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _note,
                              maxLines: 2,
                              maxLength: 200,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Instructions pour le livreur (facultatif)',
                                hintText: 'Digicode, point de repère…',
                                prefixIcon: Icon(Icons.edit_note_rounded),
                              ),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _saveAddress,
                              onChanged: (v) =>
                                  setState(() => _saveAddress = v ?? false),
                              title: const Text(
                                  'Enregistrer cette adresse dans mon profil',
                                  style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ),

                      // 3. Mode de livraison
                      _section(
                        3,
                        'Mode de livraison',
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.ink, width: 1.4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Livraison standard',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text('Délai estimé : $kDeliveryEstimate',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              Text(fee == 0 ? 'Gratuite' : dt(fee),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: fee == 0
                                          ? AppColors.olive
                                          : AppColors.ink)),
                            ],
                          ),
                        ),
                      ),

                      // 4. Récapitulatif
                      _section(
                        4,
                        'Récapitulatif',
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                for (final l in lines)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 52,
                                            height: 52,
                                            child: ProductImage(
                                                product: l.product),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(l.product.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  '${l.quantity} × ${dt(l.product.price)}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.muted)),
                                            ],
                                          ),
                                        ),
                                        Text(dt(l.subtotal),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                const Divider(height: 24),
                                _row('Sous-total', dt(subtotal)),
                                _row('Livraison', fee == 0 ? 'Gratuite' : dt(fee),
                                    color: fee == 0 ? AppColors.olive : null),
                                const Divider(height: 24),
                                _row('Total à payer', dt(total), bold: true),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Conditions de vente
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          _terms = !_terms;
                          if (_terms) _termsError = false;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _terms,
                                onChanged: (v) => setState(() {
                                  _terms = v ?? false;
                                  if (_terms) _termsError = false;
                                }),
                                isError: _termsError,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'J\'ai lu et j\'accepte les ',
                                      children: [
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.baseline,
                                          baseline: TextBaseline.alphabetic,
                                          child: GestureDetector(
                                            onTap: _showTerms,
                                            child: const Text(
                                              'conditions générales de vente',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_termsError)
                        const Padding(
                          padding: EdgeInsets.only(left: 14, bottom: 8),
                          child: Text('Vous devez accepter les conditions',
                              style: TextStyle(
                                  color: AppColors.harissa, fontSize: 12)),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lilac,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Le paiement sera ajouté à la prochaine étape. '
                                'Pour l\'instant, votre commande est enregistrée '
                                'avec le statut « En attente ».',
                                style: TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(dt(total),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (placing || !stockOk)
                        ? null
                        : () => _confirm(stockOk),
                    icon: placing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                        placing ? 'Enregistrement...' : 'Confirmer la commande'),
                  ),
                ],
              ),
            ),
          const FooterView(current: FooterTab.cart),
        ],
      ),
    );
  }
}