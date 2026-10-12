class CartItem {
  final String productId;
  final int quantity;

  const CartItem({required this.productId, required this.quantity});

  factory CartItem.fromMap(String productId, Map<String, dynamic> m) {
    return CartItem(
      productId: productId,
      quantity: (m['quantity'] ?? 1).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {'quantity': quantity};
}