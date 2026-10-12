import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class ProductFormView extends StatefulWidget {
  final ProductModel? product; // null = ajout, sinon modification
  const ProductFormView({super.key, this.product});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _category;

  Uint8List? _newBytes; // photo choisie pendant cette session
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  bool get _canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _hasImage =>
      _newBytes != null ||
      widget.product?.imageBytes != null ||
      (widget.product?.imageUrl.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? '${p.price}' : '');
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '');
    _category = TextEditingController(text: p?.category ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock, _category]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _chooseSource() async {
    if (!_canUseCamera) {
      _pick(ImageSource.gallery);
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 700,
        maxHeight: 700,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 600 * 1024) {
        if (mounted) _snack('Image trop lourde, choisissez-en une plus légère.');
        return;
      }
      if (!mounted) return;
      setState(() => _newBytes = bytes);
    } catch (e) {
      if (mounted) _snack('Impossible de charger l\'image : $e');
    }
  }

  Widget _preview() {
    final bytes = _newBytes ?? widget.product?.imageBytes;
    if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover);
    final url = widget.product?.imageUrl ?? '';
    if (url.isNotEmpty) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Text('Image introuvable')));
    }
    return const Center(child: Icon(Icons.add_a_photo_outlined, size: 48));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasImage) {
      _snack('Choisissez une photo pour le produit.');
      return;
    }
    setState(() => _saving = true);

    final old = widget.product;
    final product = ProductModel(
      id: old?.id ?? '',
      name: _name.text.trim(),
      description: _desc.text.trim(),
      price: double.parse(_price.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stock.text.trim()),
      category: _category.text.trim(),
      imageBase64:
          _newBytes != null ? base64Encode(_newBytes!) : (old?.imageBase64 ?? ''),
      imageUrl: _newBytes != null ? '' : (old?.imageUrl ?? ''),
      popularity: old?.popularity ?? 0,
      ratingAvg: old?.ratingAvg ?? 0,
      ratingCount: old?.ratingCount ?? 0,
    );

    final err = await context.read<ProductController>().saveProduct(product);
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      _snack(err);
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Produit modifié.' : 'Produit ajouté.')));
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductController>().categories;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Modifier le produit' : 'Nouveau produit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _chooseSource,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _preview(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _chooseSource,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_hasImage ? 'Changer la photo' : 'Choisir une photo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nom du produit',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Saisissez un nom'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Saisissez une description'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Prix (DT)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) {
                          final n = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Prix invalide';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Stock invalide';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _category,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Saisissez une catégorie'
                      : null,
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in categories)
                        ActionChip(
                          label: Text(c),
                          onPressed: () => setState(() => _category.text = c),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter le produit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Affiche l'image d'un produit : locale (base64), sinon URL, sinon icône.
class ProductImage extends StatelessWidget {
  final ProductModel product;
  final BoxFit fit;
  const ProductImage({super.key, required this.product, this.fit = BoxFit.cover});

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined),
      );

  @override
  Widget build(BuildContext context) {
    final bytes = product.imageBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }
    if (product.imageUrl.isNotEmpty) {
      return Image.network(
        product.imageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (c, child, p) =>
            p == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (c, _, __) => _placeholder(c),
      );
    }
    return _placeholder(context);
  }
}