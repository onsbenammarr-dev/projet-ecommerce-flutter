import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/product_controller.dart';
import 'theme/app_theme.dart';
import 'views/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        // Le panier et les favoris suivent l'utilisateur connecté
        ChangeNotifierProxyProvider<AuthController, CartController>(
          create: (_) => CartController(),
          update: (_, auth, cart) => cart!..bindUser(auth.firebaseUser?.uid),
        ),
        ChangeNotifierProxyProvider<AuthController, FavoritesController>(
          create: (_) => FavoritesController(),
          update: (_, auth, fav) => fav!..bindUser(auth.firebaseUser?.uid),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}