import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Set<String> _expandedMedicines = <String>{};
  final Map<String, TextEditingController> _stockControllers = <String, TextEditingController>{};
  final List<MedicineInventoryItem> _inventoryItems = <MedicineInventoryItem>[
    const MedicineInventoryItem(
      name: 'Metformin 500mg',
      stock: 120,
      supplier: 'Square Pharma',
    ),
    const MedicineInventoryItem(
      name: 'Amoxicillin 250mg',
      stock: 60,
      supplier: 'Beximco Pharma',
    ),
    const MedicineInventoryItem(
      name: 'Cetirizine 10mg',
      stock: 80,
      supplier: 'Incepta',
    ),
  ];

  Future<void> _addMedicineToInventory() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController stockController = TextEditingController();

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add medicine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Medicine name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(labelText: 'Supplier'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Initial stock'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final String name = nameController.text.trim();
    final String supplier = supplierController.text.trim();
    final int stock = int.tryParse(stockController.text.trim()) ?? 0;

    if (name.isEmpty || supplier.isEmpty || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid medicine details.')),
      );
      return;
    }

    setState(() {
      _inventoryItems.add(
        MedicineInventoryItem(
          name: name,
          supplier: supplier,
          stock: stock,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $name to the inventory list.')),
    );
  }

  void _changeStock(MedicineInventoryItem item, int delta) {
    setState(() {
      final int updatedStock = item.stock + delta;
      if (updatedStock < 0) {
        return;
      }

      final int index = _inventoryItems.indexWhere((MedicineInventoryItem inventoryItem) => inventoryItem.name == item.name);
      if (index != -1) {
        _inventoryItems[index] = MedicineInventoryItem(
          name: item.name,
          supplier: item.supplier,
          stock: updatedStock,
        );
      }
    });
  }

  TextEditingController _controllerFor(MedicineInventoryItem item) {
    if (!_stockControllers.containsKey(item.name)) {
      _stockControllers[item.name] = TextEditingController(text: '1');
    }
    return _stockControllers[item.name]!;
  }

  void _applyStockChange(MedicineInventoryItem item, {required bool add}) {
    final TextEditingController controller = _controllerFor(item);
    final int amount = int.tryParse(controller.text.trim()) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number greater than 0.')),
      );
      return;
    }

    _changeStock(item, add ? amount : -amount);
    controller.clear();
  }

  void _removeMedicine(MedicineInventoryItem item) {
    setState(() {
      _inventoryItems.removeWhere((MedicineInventoryItem inventoryItem) => inventoryItem.name == item.name);
      _expandedMedicines.remove(item.name);
      _stockControllers.remove(item.name);
    });
  }

  void _toggleExpanded(MedicineInventoryItem item) {
    setState(() {
      if (_expandedMedicines.contains(item.name)) {
        _expandedMedicines.remove(item.name);
      } else {
        _expandedMedicines.add(item.name);
      }
    });
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Medicine Inventory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _addMedicineToInventory,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Text(
                  'Total medicines: ${_inventoryItems.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              itemCount: _inventoryItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _inventoryItems[index];
                final bool expanded = _expandedMedicines.contains(item.name);

                return GestureDetector(
                  onTap: () => _toggleExpanded(item),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              color: MColors.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.supplier,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.stock} pcs',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: MColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MColors.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controllerFor(item),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      hintText: 'Enter number',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: () => _applyStockChange(item, add: true),
                                  icon: const Icon(Icons.add_circle_outline),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                    foregroundColor: const Color.fromARGB(255, 66, 237, 31),
                                  ),
                                  tooltip: 'Add stock',
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: () => _applyStockChange(item, add: false),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                    foregroundColor: const Color.fromARGB(255, 200, 39, 39),
                                  ),
                                  tooltip: 'Subtract stock',
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: () => _removeMedicine(item),
                                  icon: const Icon(Icons.delete_outline),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  tooltip: 'Delete medicine',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
