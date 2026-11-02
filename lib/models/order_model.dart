import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] ?? 0).toDouble(),
        quantity: (m['quantity'] ?? 1).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

/// Coordonnées de livraison saisies par le client
class ShippingInfo {
  final String fullName;
  final String phone; // 8 chiffres, sans indicatif
  final String governorate;
  final String city;
  final String address;
  final String postalCode;
  final String note;
  final double? latitude; // position GPS (facultative)
  final double? longitude;

  const ShippingInfo({
    required this.fullName,
    required this.phone,
    required this.governorate,
    required this.city,
    required this.address,
    required this.postalCode,
    this.note = '',
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Adresse sur une ligne
  String get formatted => '$address, $postalCode $city, $governorate';

  factory ShippingInfo.fromMap(Map<String, dynamic> m) => ShippingInfo(
        fullName: m['fullName'] ?? '',
        phone: m['phone'] ?? '',
        governorate: m['governorate'] ?? '',
        city: m['city'] ?? '',
        address: m['address'] ?? '',
        postalCode: m['postalCode'] ?? '',
        note: m['note'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'governorate': governorate,
        'city': city,
        'address': address,
        'postalCode': postalCode,
        'note': note,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double discount; // remise fidélité en DT
  final int pointsUsed; // points dépensés sur cette commande
  final int pointsEarned; // points gagnés par cette commande
  final double total;
  final String address; // adresse sur une ligne
  final ShippingInfo? shipping;
  final DateTime? createdAt;
  final String status; // en_attente | confirmee | annulee
  final String paymentStatus; // en_attente | paye | refuse
  final String paymentMethod; // carte | livraison
  final String? paymentReference;
  final DateTime? paidAt;
  final String? deliveryCompanyId;
  final String deliveryStatus; // en_preparation | expediee | en_cours | livree

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.address,
    required this.shipping,
    required this.createdAt,
    this.pointsUsed = 0,
    this.pointsEarned = 0,
    this.status = 'en_attente',
    this.paymentStatus = 'en_attente',
    this.paymentMethod = '',
    this.paymentReference,
    this.paidAt,
    this.deliveryCompanyId,
    this.deliveryStatus = 'en_preparation',
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) {
    final ship = m['shipping'];
    return OrderModel(
      id: id,
      userId: m['userId'] ?? '',
      items: ((m['items'] ?? []) as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (m['subtotal'] ?? 0).toDouble(),
      shippingFee: (m['shippingFee'] ?? 0).toDouble(),
      discount: (m['discount'] ?? 0).toDouble(),
      pointsUsed: (m['pointsUsed'] ?? 0).toInt(),
      pointsEarned: (m['pointsEarned'] ?? 0).toInt(),
      total: (m['total'] ?? 0).toDouble(),
      address: m['address'] ?? '',
      shipping: ship is Map
          ? ShippingInfo.fromMap(Map<String, dynamic>.from(ship))
          : null,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      status: m['status'] ?? 'en_attente',
      paymentStatus: m['paymentStatus'] ?? 'en_attente',
      paymentMethod: m['paymentMethod'] ?? '',
      paymentReference: m['paymentReference'],
      paidAt: (m['paidAt'] as Timestamp?)?.toDate(),
      deliveryCompanyId: m['deliveryCompanyId'],
      deliveryStatus: m['deliveryStatus'] ?? 'en_preparation',
    );
  }

  bool get isPaid => paymentStatus == 'paye';

  /// Référence courte à montrer au client
  String get shortId =>
      (id.length > 6 ? id.substring(0, 6) : id).toUpperCase();

  String get dateLabel {
    final d = createdAt;
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  static const _statusLabels = {
    'en_attente': 'En attente',
    'confirmee': 'Confirmée',
    'annulee': 'Annulée',
  };

  static const _deliveryLabels = {
    'en_preparation': 'En préparation',
    'expediee': 'Expédiée',
    'en_cours': 'En cours de livraison',
    'livree': 'Livrée',
  };

  String get statusLabel => _statusLabels[status] ?? status;
  String get deliveryLabel => _deliveryLabels[deliveryStatus] ?? deliveryStatus;
}