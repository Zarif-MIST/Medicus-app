enum InventoryTransactionType { restock, adjustment, dispensed, added, removed }

class InventoryTransaction {
  const InventoryTransaction({
    required this.medicineName,
    required this.type,
    required this.delta,
    required this.resultingStock,
    required this.reason,
    required this.timestamp,
  });

  final String medicineName;
  final InventoryTransactionType type;

  /// Positive for stock added, negative for stock removed.
  final int delta;
  final int resultingStock;
  final String reason;
  final DateTime timestamp;
}
