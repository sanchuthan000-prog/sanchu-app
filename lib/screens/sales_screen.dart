import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs_and_widgets.dart';

class SalesScreen extends StatefulWidget {
  final FreeFireId? preselectedId;

  const SalesScreen({Key? key, this.preselectedId}) : super(key: key);

  @override
  State<SalesScreen> createState() => SalesScreenState();
}

class SalesScreenState extends State<SalesScreen> {
  String searchQuery = '';
  String filterTime = 'All Time'; // 'All Time' | 'Today' | 'This Month'

  @override
  void initState() {
    super.initState();
    if (widget.preselectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showRecordSaleModal(context, initialId: widget.preselectedId);
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
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final thisMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

        final filteredSales = storage.sales.where((sale) {
          final query = searchQuery.toLowerCase();
          final matchesSearch = sale.idName.toLowerCase().contains(query) ||
              sale.uid.toLowerCase().contains(query) ||
              sale.buyerName.toLowerCase().contains(query);

          bool matchesTime = true;
          if (filterTime == 'Today') {
            matchesTime = sale.date == todayStr;
          } else if (filterTime == 'This Month') {
            matchesTime = sale.date.startsWith(thisMonthStr);
          }
          return matchesSearch && matchesTime;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sales Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: AppTheme.neonCyan),
                onPressed: () => showRecordSaleModal(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Metric Summary Tiles
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryTile('Total Revenue', '$currency ${storage.totalSalesRevenue.toStringAsFixed(0)}', AppTheme.primaryBlue),
                    Container(width: 1, height: 35, color: AppTheme.dividerColor),
                    _buildSummaryTile('Total Profit', '+$currency ${storage.totalNetProfit.toStringAsFixed(0)}', AppTheme.emeraldGreen),
                    Container(width: 1, height: 35, color: AppTheme.dividerColor),
                    _buildSummaryTile('Accounts Sold', '${storage.soldAccountsCount} IDs', AppTheme.neonCyan),
                  ],
                ),
              ),

              // Filters & Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                        hintText: 'Search by Buyer, Account Title, UID...',
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['All Time', 'Today', 'This Month'].map((timeOption) {
                        final isSelected = filterTime == timeOption;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(timeOption),
                            selected: isSelected,
                            onSelected: (_) => setState(() => filterTime = timeOption),
                            backgroundColor: AppTheme.surfaceLight,
                            selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryBlue,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Sales List
              Expanded(
                child: filteredSales.isEmpty
                    ? const Center(child: Text('No sales records found', style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
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
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isPartial ? AppTheme.amberWarning.withOpacity(0.15) : AppTheme.emeraldGreen.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isPartial ? AppTheme.amberWarning : AppTheme.emeraldGreen),
                                        ),
                                        child: Text(
                                          isPartial ? 'DEO: Rs. ${sale.remainingDeo.toStringAsFixed(0)}' : 'FULL PAID',
                                          style: TextStyle(
                                            color: isPartial ? AppTheme.amberWarning : AppTheme.emeraldGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Buyer: ${sale.buyerName} (${sale.buyerPhone}) · UID: ${sale.uid}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),

                                  // Financials
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildNumberCol('Deal Price', '$currency ${sale.salePrice.toStringAsFixed(0)}', AppTheme.primaryBlue),
                                      _buildNumberCol('Cost Price', '$currency ${sale.costPrice.toStringAsFixed(0)}', AppTheme.textSecondary),
                                      _buildNumberCol('Paid Upfront', '$currency ${sale.paidAmount.toStringAsFixed(0)}', AppTheme.emeraldGreen),
                                      _buildNumberCol('Net Profit', '+$currency ${sale.profit.toStringAsFixed(0)}', AppTheme.emeraldGreen, isBold: true),
                                    ],
                                  ),
                                  const Divider(color: AppTheme.dividerColor, height: 18),

                                  // Card Actions: Invoice & Delete
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${sale.date} · ${sale.paymentMethod}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.receipt_long, size: 14),
                                            label: const Text('Invoice'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.neonCyan,
                                              side: const BorderSide(color: AppTheme.cardBorder),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              textStyle: const TextStyle(fontSize: 11),
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => InvoiceReceiptDialog(
                                                  sale: sale,
                                                  storeName: storage.settings.storeName,
                                                  storePhone: storage.settings.storePhone,
                                                  currency: currency,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppTheme.roseRed, size: 18),
                                            onPressed: () => _confirmDeleteSale(context, sale),
                                          ),
                                        ],
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
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.flash_on),
            label: const Text('RECORD SALE'),
            onPressed: () => showRecordSaleModal(context),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildNumberCol(String label, String val, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12, color: color)),
      ],
    );
  }

  void showRecordSaleModal(BuildContext context, {FreeFireId? initialId}) {
    final storage = StorageService();
    final availableIds = storage.ids.where((id) => id.status.toLowerCase() == 'available' || id.id == initialId?.id).toList();

    if (availableIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available Free Fire accounts to sell! Please add an ID first.')),
      );
      return;
    }

    FreeFireId selectedId = initialId ?? availableIds.first;
    String selectedBuyer = storage.buyers.isNotEmpty ? storage.buyers.first.name : '+ Add New Buyer...';
    bool isNewBuyer = storage.buyers.isEmpty;
    final newBuyerNameCtrl = TextEditingController();
    final newBuyerPhoneCtrl = TextEditingController();
    final newBuyerAddressCtrl = TextEditingController();

    final salePriceCtrl = TextEditingController(text: selectedId.price.toStringAsFixed(0));
    final costPriceCtrl = TextEditingController(text: selectedId.costPrice.toStringAsFixed(0));
    final paidAmountCtrl = TextEditingController(text: selectedId.price.toStringAsFixed(0));
    final dueDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))));
    final overdueFineCtrl = TextEditingController(text: '50');
    final txnIdCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String paymentMethod = 'GPay / UPI';
    String bankName = 'Commercial Bank';
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
              left: 18,
              right: 18,
              top: 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Record Account Sale',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Pick Account
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
                    decoration: const InputDecoration(labelText: 'Select Free Fire Account *'),
                  ),
                  const SizedBox(height: 10),

                  // Buyer Selection
                  DropdownButtonFormField<String>(
                    value: isNewBuyer ? '+ Add New Buyer...' : selectedBuyer,
                    dropdownColor: AppTheme.surfaceLight,
                    items: [
                      ...storage.buyers.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name))),
                      const DropdownMenuItem(value: '+ Add New Buyer...', child: Text('+ Add New Buyer...', style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        if (val == '+ Add New Buyer...') {
                          isNewBuyer = true;
                        } else {
                          isNewBuyer = false;
                          selectedBuyer = val ?? '';
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Buyer Profile *'),
                  ),

                  if (isNewBuyer) ...[
                    const SizedBox(height: 8),
                    TextField(controller: newBuyerNameCtrl, decoration: const InputDecoration(labelText: 'New Buyer Name *')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: newBuyerPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone / WhatsApp'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: newBuyerAddressCtrl, decoration: const InputDecoration(labelText: 'City / Address'))),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Pricing row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: salePriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Agreed Sale Price *'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: costPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cost Price (Rs.)'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: paidAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Paid Now (Upfront) *'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Deal Profit', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              Text(
                                '+Rs. ${calcProfit.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: calcProfit >= 0 ? AppTheme.emeraldGreen : AppTheme.roseRed),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // DEO Terms (if remaining > 0)
                  if (calcRemaining > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.amberWarning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.amberWarning.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('DEO / BALANCE TERMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.amberWarning)),
                              Text('Remaining: Rs. ${calcRemaining.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.amberWarning)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: dueDateCtrl, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: overdueFineCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily Fine (Rs.)'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Payment Method & Bank
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: paymentMethod,
                          dropdownColor: AppTheme.surfaceLight,
                          items: ['GPay / UPI', 'Bank Transfer', 'Cash', 'EzCash', 'Other'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setModalState(() => paymentMethod = val ?? paymentMethod),
                          decoration: const InputDecoration(labelText: 'Payment Method'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: bankName,
                          dropdownColor: AppTheme.surfaceLight,
                          items: ['Commercial Bank', 'Bank of Ceylon', 'People\'s Bank', 'Sampath', 'HNB', 'Seylan', 'Other'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setModalState(() => bankName = val ?? bankName),
                          decoration: const InputDecoration(labelText: 'Bank Name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: txnIdCtrl, decoration: const InputDecoration(labelText: 'Deposit Slip / Txn ID')),
                  const SizedBox(height: 10),

                  // Profit sync confirmation checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Add profit (+Rs. ${calcProfit.toStringAsFixed(0)}) to Money Control?',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                    subtitle: const Text('Preserves separate personal cashflow', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    value: linkToMoneyEntries,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (val) => setModalState(() => linkToMoneyEntries = val ?? true),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('COMPLETE & RECORD SALE'),
                      onPressed: () async {
                        String finalBuyer = selectedBuyer;
                        String finalPhone = '';
                        if (isNewBuyer) {
                          if (newBuyerNameCtrl.text.isEmpty) return;
                          finalBuyer = newBuyerNameCtrl.text;
                          finalPhone = newBuyerPhoneCtrl.text;
                          storage.addBuyer(Buyer(
                            id: 'b-${DateTime.now().millisecondsSinceEpoch}',
                            name: finalBuyer,
                            phone: finalPhone,
                            address: newBuyerAddressCtrl.text,
                          ));
                        } else {
                          final b = storage.buyers.firstWhere((b) => b.name == selectedBuyer, orElse: () => Buyer(id: '', name: selectedBuyer));
                          finalPhone = b.phone;
                        }

                        final sale = Sale(
                          id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
                          idRecordId: selectedId.id,
                          idName: selectedId.name,
                          uid: selectedId.uid,
                          buyerName: finalBuyer,
                          buyerPhone: finalPhone,
                          salePrice: salePrice,
                          costPrice: costPrice,
                          paidAmount: paidAmount,
                          paymentMethod: paymentMethod,
                          bankName: bankName,
                          txnId: txnIdCtrl.text,
                          dueDate: dueDateCtrl.text,
                          overdueFinePerDay: double.tryParse(overdueFineCtrl.text) ?? 50.0,
                          notes: notesCtrl.text,
                        );

                        final success = await storage.createSale(sale, linkToMoneyEntries: linkToMoneyEntries);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Duplicate sale detected for this account!')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sale completed for ${selectedId.name}!')),
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
        content: Text('Delete deal record for ${sale.idName}?\nThis also removes its linked profit entry from Money Control.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
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
