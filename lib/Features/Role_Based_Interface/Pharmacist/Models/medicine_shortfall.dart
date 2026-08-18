class MedicineShortfall {
  const MedicineShortfall({
    required this.medicineName,
    required this.requiredQuantity,
    required this.availableStock,
  });

  final String medicineName;
  final int requiredQuantity;
  final int availableStock;

  bool get isOutOfStock => availableStock <= 0;
}

/// Thrown when a prescription can't be dispensed because one or more of its
/// medicines are unavailable or understocked in inventory.
class InsufficientStockException implements Exception {
  const InsufficientStockException(this.shortfalls);

  final List<MedicineShortfall> shortfalls;

  String get message {
    return shortfalls
        .map((MedicineShortfall s) => s.isOutOfStock
            ? '${s.medicineName} is out of stock'
            : '${s.medicineName}: need ${s.requiredQuantity}, only ${s.availableStock} left')
        .join('\n');
  }

  @override
  String toString() => 'InsufficientStockException: $message';
}
