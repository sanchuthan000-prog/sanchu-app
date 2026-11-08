import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SalesScreen extends StatefulWidget {
  final FreeFireId? preselectedId;

  const SalesScreen({Key? key, this.preselectedId}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preselectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateSaleDialog(context, initialId: widget.preselectedId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sales Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryCyan),
                onPressed: () => _showCreateSaleDialog(context),
              ),
            ],
          ),
          body: storage.sales.isEmpty
              ? const Center(
                  child: Text('No sales recorded yet. Click + to create a sale.', style: TextStyle(color: AppTheme.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: storage.sales.length,
                  itemBuilder: (context, index) {
                    final sale = storage.sales[index];
                    final isPartial = sale.remainingDeo > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    sale.idName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPartial ? AppTheme.neonAmber.withOpacity(0.15) : AppTheme.neonGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isPartial ? AppTheme.neonAmber : AppTheme.neonGreen),
                                  ),
                                  child: Text(
                                    isPartial ? 'DEO PENDING' : 'FULL PAID',
                                    style: TextStyle(
                                      color: isPartial ? AppTheme.neonAmber : AppTheme.neonGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Buyer: ${sale.buyerName} (${sale.buyerPhone.isNotEmpty ? sale.buyerPhone : "No phone"}) · UID: ${sale.uid}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 10),

                            // Financial Numbers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildNumberCol('Deal Price', '$currency ${sale.salePrice.toStringAsFixed(0)}', AppTheme.primaryCyan),
                                _buildNumberCol('Paid Upfront', '$currency ${sale.paidAmount.toStringAsFixed(0)}', AppTheme.neonGreen),
                                _buildNumberCol('Balance Due', '$currency ${sale.remainingDeo.toStringAsFixed(0)}', isPartial ? AppTheme.neonRed : AppTheme.textMuted),
                                _buildNumberCol('Deal Profit', '+$currency ${sale.profit.toStringAsFixed(0)}', AppTheme.neonGreen),
                              ],
                            ),
                            const Divider(color: AppTheme.dividerColor, height: 20),

                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${sale.date} · ${sale.paymentMethod}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.neonRed, size: 20),
                                  onPressed: () => _confirmDeleteSale(context, sale),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryCyan,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('NEW SALE'),
            onPressed: () => _showCreateSaleDialog(context),
          ),
        );
      },
    );
  }

  Widget _buildNumberCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  void _showCreateSaleDialog(BuildContext context, {FreeFireId? initialId}) {
    final storage = StorageService();
    final availableIds = storage.ids.where((id) => id.status.toLowerCase() == 'available' || id.id == initialId?.id).toList();

    if (availableIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available Free Fire accounts to sell! Please add an ID first.')),
      );
      return;
    }

    FreeFireId selectedId = initialId ?? availableIds.first;
    final buyerNameCtrl = TextEditingController();
    final buyerPhoneCtrl = TextEditingController();
    final salePriceCtrl = TextEditingController(text: selectedId.price.toStringAsFixed(0));
    final costPriceCtrl = TextEditingController(text: selectedId.costPrice.toStringAsFixed(0));
    final paidAmountCtrl = TextEditingController(text: selectedId.price.toStringAsFixed(0));
    String paymentMethod = 'GPay / UPI';
    bool linkToMoneyEntries = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final salePrice = double.tryParse(salePriceCtrl.text) ?? 0.0;
          final costPrice = double.tryParse(costPriceCtrl.text) ?? 0.0;
          final paidAmount = double.tryParse(paidAmountCtrl.text) ?? 0.0;
          final calcProfit = salePrice - costPrice;
          final calcRemaining = (salePrice - paidAmount).clamp(0.0, double.infinity);

          return Padding(
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
                  const Text(
                    'Record New Free Fire Sale',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
                  ),
                  const SizedBox(height: 14),

                  // Select Account
                  const Text('Select Free Fire Account:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedId.id,
                    dropdownColor: AppTheme.surfaceLight,
                    isExpanded: true,
                    items: availableIds.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.uid})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final item = availableIds.firstWhere((e) => e.id == val);
                      setModalState(() {
                        selectedId = item;
                        salePriceCtrl.text = item.price.toStringAsFixed(0);
                        costPriceCtrl.text = item.costPrice.toStringAsFixed(0);
                        paidAmountCtrl.text = item.price.toStringAsFixed(0);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Buyer details
                  TextField(controller: buyerNameCtrl, decoration: const InputDecoration(labelText: 'Buyer / Customer Name')),
                  const SizedBox(height: 10),
                  TextField(controller: buyerPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Buyer Phone (WhatsApp)')),
                  const SizedBox(height: 10),

                  // Deal Prices
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: salePriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sale Deal Price'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: costPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Account Cost Price'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Paid Amount
                  TextField(
                    controller: paidAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Paid Amount (Upfront)'),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Live Profit & Due Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Estimated Profit', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              '+Rs. ${calcProfit.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: calcProfit >= 0 ? AppTheme.neonGreen : AppTheme.neonRed,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Remaining DEO', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${calcRemaining.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: calcRemaining > 0 ? AppTheme.neonAmber : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Profit-Only Money Control Confirmation Checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Add profit (Rs. ${calcProfit.toStringAsFixed(0)}) to Personal Money Control?',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    subtitle: const Text('Keeps gross sales separate, records profit only', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    value: linkToMoneyEntries,
                    activeColor: AppTheme.neonGreen,
                    onChanged: (val) => setModalState(() => linkToMoneyEntries = val ?? true),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('CONFIRM & COMPLETE SALE'),
                      onPressed: () async {
                        if (buyerNameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter buyer name')));
                          return;
                        }

                        final sale = Sale(
                          id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
                          idRecordId: selectedId.id,
                          idName: selectedId.name,
                          uid: selectedId.uid,
                          buyerName: buyerNameCtrl.text,
                          buyerPhone: buyerPhoneCtrl.text,
                          salePrice: salePrice,
                          costPrice: costPrice,
                          paidAmount: paidAmount,
                          paymentMethod: paymentMethod,
                        );

                        final success = await storage.createSale(sale, linkToMoneyEntries: linkToMoneyEntries);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: Duplicate sale! This account is already recorded as sold.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sale completed successfully for ${selectedId.name}!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteSale(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Sale Transaction?'),
        content: Text('Delete sale for ${sale.idName}?\nThis will also remove its linked profit entry from Personal Money.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonRed),
            child: const Text('Delete'),
            onPressed: () {
              StorageService().deleteSale(sale.id, removeLinkedProfit: true);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
