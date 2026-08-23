import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/inventory_transaction.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.pharmacistId});

  final String pharmacistId;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Set<String> _expandedMedicines = <String>{};
  final Map<String, TextEditingController> _stockControllers = <String, TextEditingController>{};
  List<MedicineInventoryItem> _inventoryItems = <MedicineInventoryItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final List<MedicineInventoryItem> items =
        await PharmacistService.instance.getInventory(widget.pharmacistId);
    if (!mounted) {
      return;
    }
    setState(() {
      _inventoryItems = items;
      _isLoading = false;
    });
  }

  Future<void> _addMedicineToInventory() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    final TextEditingController thresholdController = TextEditingController();

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add medicine'),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
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
                const SizedBox(height: 12),
                TextField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Restock alert level',
                    hintText: 'Defaults to 20',
                  ),
                ),
              ],
            ),
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
    final int? threshold = int.tryParse(thresholdController.text.trim());

    if (name.isEmpty || supplier.isEmpty || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid medicine details.')),
      );
      return;
    }

    await PharmacistService.instance.addInventoryItem(
      widget.pharmacistId,
      MedicineInventoryItem(
        name: name,
        supplier: supplier,
        stock: stock,
        lowStockThreshold: threshold != null && threshold >= 0 ? threshold : 20,
      ),
    );
    await _loadInventory();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $name to the inventory list.')),
    );
  }

  Future<void> _changeStock(MedicineInventoryItem item, int delta) async {
    if (item.stock + delta < 0) {
      return;
    }
    await PharmacistService.instance.changeInventoryStock(
      widget.pharmacistId,
      item.name,
      delta,
      type: delta >= 0 ? InventoryTransactionType.restock : InventoryTransactionType.adjustment,
      reason: delta >= 0 ? 'Restocked' : 'Manual stock adjustment',
    );
    await _loadInventory();
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

  Future<void> _removeMedicine(MedicineInventoryItem item) async {
    await PharmacistService.instance.removeInventoryItem(widget.pharmacistId, item.name);
    _expandedMedicines.remove(item.name);
    _stockControllers.remove(item.name);
    await _loadInventory();
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
    final List<MedicineInventoryItem> lowStockItems = _inventoryItems
        .where((MedicineInventoryItem item) => item.isLowStock)
        .toList();

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
          if (lowStockItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _LowStockBanner(items: lowStockItems),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
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
                      border: item.isLowStock
                          ? Border.all(color: Colors.red.shade300, width: 1.2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              color: item.isLowStock ? Colors.red.shade700 : MColors.primaryColor,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.stock} pcs',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: item.isLowStock ? Colors.red.shade700 : MColors.primaryColor,
                                  ),
                                ),
                                if (item.isLowStock) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'Restock',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.items});

  final List<MedicineInventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final String names = items.map((MedicineInventoryItem item) => item.name).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} ${items.length == 1 ? 'medicine needs' : 'medicines need'} restocking',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  names,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
