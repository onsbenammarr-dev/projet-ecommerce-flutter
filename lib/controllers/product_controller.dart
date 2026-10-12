import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

enum SortOption { popularity, priceAsc, priceDesc }

class ProductController extends ChangeNotifier {
  final ProductService _service = ProductService();
  StreamSubscription<List<ProductModel>>? _sub;

  List<ProductModel> _all = [];
  bool loading = true;
  String? error;

  String query = '';
  String? category; // null = toutes
  RangeValues? priceFilter; // null = pas de filtre
  SortOption sort = SortOption.popularity;

  ProductController() {
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = _service.watchProducts().listen(
      (list) {
        _all = list;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        loading = false;
        error = 'Impossible de charger les produits. '
            'Vérifiez votre connexion puis réessayez.';
        notifyListeners();
      },
    );
  }

  /// Relance le chargement après une erreur
  void retry() {
    loading = true;
    error = null;
    notifyListeners();
    _listen();
  }

  double get maxPrice {
    if (_all.isEmpty) return 100;
    final m = _all.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    return m.ceilToDouble();
  }

  List<String> get categories {
    final set = _all.map((p) => p.category).toSet().toList();
    set.sort();
    return set;
  }

  bool get hasPriceFilter => priceFilter != null;

  /// Tous les produits, sans filtre (pour l'admin)
  List<ProductModel> get allProducts => _all;

  List<ProductModel> get products {
    var list = _all.where((p) {
      if (category != null && p.category != category) return false;
      if (query.isNotEmpty &&
          !p.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      if (priceFilter != null &&
          (p.price < priceFilter!.start || p.price > priceFilter!.end)) {
        return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case SortOption.popularity:
        list.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return list;
  }

  void setQuery(String v) {
    query = v.trim();
    notifyListeners();
  }

  void setCategory(String? c) {
    category = c;
    notifyListeners();
  }

  void setPriceFilter(RangeValues? r) {
    priceFilter = r;
    notifyListeners();
  }

  void setSort(SortOption s) {
    sort = s;
    notifyListeners();
  }

  /// Ajoute (id vide) ou modifie un produit. Renvoie null si OK, sinon l'erreur.
  Future<String?> saveProduct(ProductModel p) async {
    try {
      if (p.id.isEmpty) {
        await _service.addProduct(p);
      } else {
        await _service.updateProduct(p);
      }
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  Future<String?> seedDemo() async {
    try {
      await _service.seedDemo();
      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}