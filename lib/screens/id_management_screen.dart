import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class IdManagementScreen extends StatefulWidget {
  final Function(FreeFireId)? onQuickSell;

  const IdManagementScreen({Key? key, this.onQuickSell}) : super(key: key);

  @override
  State<IdManagementScreen> createState() => _IdManagementScreenState();
}

class _IdManagementScreenState extends State<IdManagementScreen> {
  String searchQuery = '';
  String filterStatus = 'All'; // 'All' | 'Available' | 'Sold'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        final filteredIds = storage.ids.where((item) {
          final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.uid.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.sellerName.toLowerCase().contains(searchQuery.toLowerCase());
          final matchesFilter = filterStatus == 'All' || item.status.toLowerCase() == filterStatus.toLowerCase();
          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Free Fire ID Inventory'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryCyan),
                onPressed: () => _showAddEditIdDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                        hintText: 'Search by Title, Game UID, Seller...',
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['All', 'Available', 'Sold'].map((status) {
                        final isSelected = filterStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (_) => setState(() => filterStatus = status),
                            backgroundColor: AppTheme.surfaceLight,
                            selectedColor: AppTheme.primaryCyan.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryCyan,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryCyan : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ID Inventory List
              Expanded(
                child: filteredIds.isEmpty
                    ? const Center(
                        child: Text('No Free Fire accounts found', style: TextStyle(color: AppTheme.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: filteredIds.length,
                        itemBuilder: (context, index) {
                          final item = filteredIds[index];
                          final isAvailable = item.status.toLowerCase() == 'available';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'UID: ${item.uid} · Level ${item.level} · Likes: ${item.likes}',
                                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isAvailable ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.neonRed.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isAvailable ? AppTheme.neonGreen : AppTheme.neonRed,
                                          ),
                                        ),
                                        child: Text(
                                          item.status.toUpperCase(),
                                          style: TextStyle(
                                            color: isAvailable ? AppTheme.neonGreen : AppTheme.neonRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Price & Cost Row
                                  Row(
                                    children: [
                                      Text(
                                        'Selling Price: $currency ${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Cost: $currency ${item.costPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Bind Info
                                  Text(
                                    'Bind: ${item.currentGmail.isNotEmpty ? item.currentGmail : "Clean"} · ${item.bindStatus}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                  const Divider(color: AppTheme.dividerColor, height: 20),

                                  // Action Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isAvailable && widget.onQuickSell != null)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                                          label: const Text('Sell ID'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.neonGreen,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          onPressed: () => widget.onQuickSell!(item),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryCyan, size: 20),
                                        onPressed: () => _showAddEditIdDialog(context, idItem: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.neonRed, size: 20),
                                        onPressed: () => _confirmDelete(context, item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryCyan,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('ADD ID'),
            onPressed: () => _showAddEditIdDialog(context),
          ),
        );
      },
    );
  }

  void _showAddEditIdDialog(BuildContext context, {FreeFireId? idItem}) {
    final isEdit = idItem != null;
    final nameCtrl = TextEditingController(text: idItem?.name ?? '');
    final uidCtrl = TextEditingController(text: idItem?.uid ?? '');
    final levelCtrl = TextEditingController(text: idItem != null ? '${idItem.level}' : '65');
    final priceCtrl = TextEditingController(text: idItem != null ? '${idItem.price.toStringAsFixed(0)}' : '');
    final costCtrl = TextEditingController(text: idItem != null ? '${idItem.costPrice.toStringAsFixed(0)}' : '');
    final gmailCtrl = TextEditingController(text: idItem?.currentGmail ?? '');
    final sellerCtrl = TextEditingController(text: idItem?.sellerName ?? '');
    String status = idItem?.status ?? 'Available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Free Fire ID' : 'Add New Free Fire ID',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Title / Bundle highlights')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: uidCtrl, decoration: const InputDecoration(labelText: 'Game UID'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: levelCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Level'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (Rs.)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (Rs.)'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: gmailCtrl, decoration: const InputDecoration(labelText: 'Current Linked Gmail')),
                const SizedBox(height: 10),
                TextField(controller: sellerCtrl, decoration: const InputDecoration(labelText: 'Seller / Supplier Reference')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(color: AppTheme.textSecondary)),
                    DropdownButton<String>(
                      value: status,
                      dropdownColor: AppTheme.surfaceLight,
                      items: ['Available', 'Sold', 'Reserved'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setModalState(() => status = val ?? status),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text(isEdit ? 'UPDATE ACCOUNT' : 'SAVE ACCOUNT'),
                    onPressed: () {
                      if (nameCtrl.text.isEmpty || uidCtrl.text.isEmpty) return;
                      final storage = StorageService();
                      if (isEdit) {
                        idItem.name = nameCtrl.text;
                        idItem.uid = uidCtrl.text;
                        idItem.level = int.tryParse(levelCtrl.text) ?? 1;
                        idItem.price = double.tryParse(priceCtrl.text) ?? 0.0;
                        idItem.costPrice = double.tryParse(costCtrl.text) ?? 0.0;
                        idItem.currentGmail = gmailCtrl.text;
                        idItem.sellerName = sellerCtrl.text;
                        idItem.status = status;
                        storage.updateId(idItem);
                      } else {
                        final newId = FreeFireId(
                          id: 'ff-${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text,
                          uid: uidCtrl.text,
                          level: int.tryParse(levelCtrl.text) ?? 1,
                          price: double.tryParse(priceCtrl.text) ?? 0.0,
                          costPrice: double.tryParse(costCtrl.text) ?? 0.0,
                          currentGmail: gmailCtrl.text,
                          sellerName: sellerCtrl.text,
                          status: status,
                        );
                        storage.addId(newId);
                      }
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FreeFireId item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to delete ${item.name} (${item.uid})?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonRed),
            child: const Text('Delete'),
            onPressed: () {
              StorageService().deleteId(item.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
