import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import '../widgets/footer_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  Uint8List? _newPhoto;
  bool _saving = false;

  bool get _canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser!;
    _name = TextEditingController(text: user.name);
    _address = TextEditingController(text: user.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
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
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 300 * 1024) {
        if (mounted) _snack('Image trop lourde, choisissez-en une plus légère.');
        return;
      }
      if (!mounted) return;
      setState(() => _newPhoto = bytes);
    } catch (e) {
      if (mounted) _snack('Impossible de charger l\'image : $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final err = await context.read<AuthController>().updateProfile(
          name: _name.text,
          address: _address.text,
          photoBase64: _newPhoto != null ? base64Encode(_newPhoto!) : null,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      _snack(err);
      return;
    }
    setState(() => _newPhoto = null);
    _snack('Profil mis à jour.');
  }

  void _logout() {
    // revient à la racine puis déconnecte : AuthGate affiche le catalogue visiteur
    Navigator.of(context).popUntil((r) => r.isFirst);
    context.read<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final photo = _newPhoto ?? user.photoBytes;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
            bottomNavigationBar: const FooterView(current: FooterTab.profile),
      body: SafeArea(
        child: FooterScroll(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.lilac,
                        backgroundImage:
                            photo != null ? MemoryImage(photo) : null,
                        child: photo == null
                            ? const Icon(Icons.person,
                                size: 56, color: AppColors.ink)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          tooltip: 'Changer la photo',
                          onPressed: _chooseSource,
                          icon: const Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _stat(Icons.receipt_long_outlined,
                          '${user.orderCount}', 'Commandes', AppColors.mint),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _stat(Icons.stars_rounded, '${user.loyaltyPoints}',
                          'Points fidélité', AppColors.peach),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Saisissez votre nom'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Adresse de livraison',
                    hintText: 'Rue, ville, code postal',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color tint) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}