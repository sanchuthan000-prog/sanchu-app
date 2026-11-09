import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BuyersSellersScreen extends StatefulWidget {
  const BuyersSellersScreen({Key? key}) : super(key: key);

  @override
  State<BuyersSellersScreen> createState() => _BuyersSellersScreenState();
}

class _BuyersSellersScreenState extends State<BuyersSellersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String buyerSearchQuery = '';
  String sellerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _launchWhatsApp(String phone, {String text = ''}) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!clean.startsWith('91') && clean.length == 10) clean = '91$clean';
    final url = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _launchPhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (_) {}
  }

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard'), backgroundColor: AppTheme.surfaceLight, duration: const Duration(seconds: 2)),
    );
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
            title: const Text('Contacts & Partners'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryCyan,
              labelColor: AppTheme.primaryCyan,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Buyers / Customers'),
                Tab(icon: Icon(Icons.storefront), text: 'Sellers / Suppliers'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBuyersTab(storage, currency),
              _buildSellersTab(storage, currency),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryCyan,
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text(
              _tabController.index == 0 ? 'Add Customer' : 'Add Supplier',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (_tabController.index == 0) {
                showAddEditBuyerModal(context);
              } else {
                showAddEditSellerModal(context);
              }
            },
          ),
        );
      },
    );
  }

  // --- BUYERS TAB ---
  Widget _buildBuyersTab(StorageService storage, String currency) {
    final filteredBuyers = storage.buyers.where((b) {
      final q = buyerSearchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) || b.phone.contains(q) || b.address.toLowerCase().contains(q);
    }).toList();

    final totalBuyers = storage.buyers.length;
    final totalSpent = storage.buyers.fold(0.0, (acc, b) => acc + b.totalPurchases);
    final totalDeo = storage.buyers.fold(0.0, (acc, b) => acc + b.totalDeo);

    return Column(
      children: [
        // KPI Summary Bar
        Container(
          color: AppTheme.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _buildKpiCard('Total Buyers', '$totalBuyers', AppTheme.primaryCyan),
              const SizedBox(width: 8),
              _buildKpiCard('Total Purchases', '$currency ${totalSpent.toStringAsFixed(0)}', AppTheme.emeraldGreen),
              const SizedBox(width: 8),
              _buildKpiCard('Active DEO Due', '$currency ${totalDeo.toStringAsFixed(0)}', AppTheme.roseRed),
            ],
          ),
        ),

        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
              hintText: 'Search Buyers by Name, Phone, City...',
            ),
            onChanged: (val) => setState(() => buyerSearchQuery = val),
          ),
        ),

        // Buyers List
        Expanded(
          child: filteredBuyers.isEmpty
              ? const Center(child: Text('No buyers found', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredBuyers.length,
                  itemBuilder: (context, index) {
                    final buyer = filteredBuyers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryCyan.withOpacity(0.15),
                                  child: const Icon(Icons.person, color: AppTheme.primaryCyan),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(buyer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(
                                        buyer.phone.isNotEmpty ? buyer.phone : 'No phone recorded',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Spent: $currency ${buyer.totalPurchases.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    if (buyer.totalDeo > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.roseRed.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'DEO: $currency ${buyer.totalDeo.toStringAsFixed(0)}',
                                          style: const TextStyle(color: AppTheme.roseRed, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (buyer.address.isNotEmpty || buyer.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${buyer.address}${buyer.address.isNotEmpty && buyer.notes.isNotEmpty ? ' · ' : ''}${buyer.notes}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                            const Divider(color: AppTheme.dividerColor, height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (buyer.phone.isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: AppTheme.emeraldGreen, size: 18),
                                        tooltip: 'WhatsApp Chat',
                                        onPressed: () => _launchWhatsApp(buyer.phone, text: 'Hello ${buyer.name}, from Alone ID Sale Store!'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: AppTheme.primaryCyan, size: 18),
                                        tooltip: 'Call Phone',
                                        onPressed: () => _launchPhoneCall(buyer.phone),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      child: const Text('Edit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      onPressed: () => showAddEditBuyerModal(context, buyerItem: buyer),
                                    ),
                                    TextButton(
                                      child: const Text('Delete', style: TextStyle(color: AppTheme.roseRed, fontSize: 12)),
                                      onPressed: () => _confirmDeleteBuyer(buyer, storage),
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
    );
  }

  // --- SELLERS TAB ---
  Widget _buildSellersTab(StorageService storage, String currency) {
    final filteredSellers = storage.sellers.where((s) {
      final q = sellerSearchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.phone.contains(q) || s.bankName.toLowerCase().contains(q) || s.upiId.toLowerCase().contains(q);
    }).toList();

    final totalSellers = storage.sellers.length;
    final totalSupplied = storage.sellers.fold(0, (acc, s) => acc + s.totalSupplied);
    final totalPaid = storage.sellers.fold(0.0, (acc, s) => acc + s.totalPaid);
    final totalPending = storage.sellers.fold(0.0, (acc, s) => acc + (s.pendingBalance ?? 0.0));

    return Column(
      children: [
        // KPI Summary Bar
        Container(
          color: AppTheme.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _buildKpiCard('Total Sellers', '$totalSellers', AppTheme.primaryCyan),
              const SizedBox(width: 8),
              _buildKpiCard('IDs Sourced', '$totalSupplied', AppTheme.emeraldGreen),
              const SizedBox(width: 8),
              _buildKpiCard('Total Paid', '$currency ${totalPaid.toStringAsFixed(0)}', AppTheme.primaryCyan),
              const SizedBox(width: 8),
              _buildKpiCard('Pending Owed', '$currency ${totalPending.toStringAsFixed(0)}', AppTheme.neonAmber),
            ],
          ),
        ),

        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
              hintText: 'Search Suppliers by Name, Phone, Bank, UPI...',
            ),
            onChanged: (val) => setState(() => sellerSearchQuery = val),
          ),
        ),

        // Sellers List
        Expanded(
          child: filteredSellers.isEmpty
              ? const Center(child: Text('No suppliers found', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredSellers.length,
                  itemBuilder: (context, index) {
                    final seller = filteredSellers[index];
                    final pending = seller.pendingBalance ?? (seller.totalSourcingCost - seller.totalPaid);

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
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.neonAmber.withOpacity(0.15),
                                  child: const Icon(Icons.store, color: AppTheme.neonAmber),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(
                                        seller.phone.isNotEmpty ? seller.phone : 'No phone recorded',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pending > 0 ? AppTheme.neonAmber.withOpacity(0.15) : AppTheme.emeraldGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: pending > 0 ? AppTheme.neonAmber : AppTheme.emeraldGreen),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        pending > 0 ? 'Pending Balance' : 'Settled Clean',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: pending > 0 ? AppTheme.neonAmber : AppTheme.emeraldGreen,
                                        ),
                                      ),
                                      Text(
                                        '$currency ${pending.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: pending > 0 ? AppTheme.neonAmber : AppTheme.emeraldGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Sourcing Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Supplied: ${seller.totalSupplied} IDs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Text('Sourced: $currency ${seller.totalSourcingCost.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Text('Paid: $currency ${seller.totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Bank & UPI Details Box
                            if (seller.bankName.isNotEmpty || seller.upiId.isNotEmpty || seller.accountNo.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (seller.bankName.isNotEmpty)
                                      Text('Bank: ${seller.bankName}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    if (seller.accountNo.isNotEmpty)
                                      Row(
                                        children: [
                                          Expanded(child: Text('A/C: ${seller.accountNo}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                                          InkWell(
                                            onTap: () => _copyText(seller.accountNo, 'Account number'),
                                            child: const Icon(Icons.copy, size: 13, color: AppTheme.primaryCyan),
                                          ),
                                        ],
                                      ),
                                    if (seller.ifsc.isNotEmpty)
                                      Text('IFSC: ${seller.ifsc}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    if (seller.upiId.isNotEmpty)
                                      Row(
                                        children: [
                                          Expanded(child: Text('UPI: ${seller.upiId}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold))),
                                          InkWell(
                                            onTap: () => _copyText(seller.upiId, 'UPI ID'),
                                            child: const Icon(Icons.copy, size: 13, color: AppTheme.primaryCyan),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            const Divider(color: AppTheme.dividerColor, height: 18),

                            // Bottom Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (seller.phone.isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: AppTheme.emeraldGreen, size: 18),
                                        tooltip: 'WhatsApp Chat',
                                        onPressed: () => _launchWhatsApp(seller.phone, text: 'Hello ${seller.name}, regarding ID sourcing from Alone ID Sale.'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: AppTheme.primaryCyan, size: 18),
                                        tooltip: 'Call Phone',
                                        onPressed: () => _launchPhoneCall(seller.phone),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.emeraldGreen,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      child: const Text('Record Payout', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showRecordPayoutModal(context, seller, currency),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                                      onPressed: () => showAddEditSellerModal(context, sellerItem: seller),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.roseRed),
                                      onPressed: () => _confirmDeleteSeller(seller, storage),
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
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // --- MODALS ---
  static void showAddEditBuyerModal(BuildContext context, {Buyer? buyerItem}) {
    final isEdit = buyerItem != null;
    final nameCtrl = TextEditingController(text: buyerItem?.name ?? '');
    final phoneCtrl = TextEditingController(text: buyerItem?.phone ?? '');
    final addressCtrl = TextEditingController(text: buyerItem?.address ?? '');
    final notesCtrl = TextEditingController(text: buyerItem?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
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
              Text(
                isEdit ? 'Edit Buyer Customer' : 'Add New Customer',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Full Name *')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone / WhatsApp Number *')),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Location / City')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (Preferences, Badges desired)')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan),
                  child: Text(isEdit ? 'Save Changes' : 'Add Customer', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final storage = StorageService();
                    if (isEdit) {
                      buyerItem.name = nameCtrl.text.trim();
                      buyerItem.phone = phoneCtrl.text.trim();
                      buyerItem.whatsapp = phoneCtrl.text.trim();
                      buyerItem.address = addressCtrl.text.trim();
                      buyerItem.notes = notesCtrl.text.trim();
                      storage.updateBuyer(buyerItem);
                    } else {
                      storage.addBuyer(Buyer(
                        id: 'b-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        whatsapp: phoneCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddEditSellerModal(BuildContext context, {Seller? sellerItem}) {
    final isEdit = sellerItem != null;
    final nameCtrl = TextEditingController(text: sellerItem?.name ?? '');
    final phoneCtrl = TextEditingController(text: sellerItem?.phone ?? '');
    final bankCtrl = TextEditingController(text: sellerItem?.bankName ?? '');
    final upiCtrl = TextEditingController(text: sellerItem?.upiId ?? '');
    final acctCtrl = TextEditingController(text: sellerItem?.accountNo ?? '');
    final ifscCtrl = TextEditingController(text: sellerItem?.ifsc ?? '');
    final notesCtrl = TextEditingController(text: sellerItem?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
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
              Text(
                isEdit ? 'Edit ID Supplier' : 'Add New ID Supplier',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier Name *')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone / WhatsApp *')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank Name'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: acctCtrl, decoration: const InputDecoration(labelText: 'Account Number'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan),
                  child: Text(isEdit ? 'Save Changes' : 'Add Supplier', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final storage = StorageService();
                    if (isEdit) {
                      sellerItem.name = nameCtrl.text.trim();
                      sellerItem.phone = phoneCtrl.text.trim();
                      sellerItem.bankName = bankCtrl.text.trim();
                      sellerItem.upiId = upiCtrl.text.trim();
                      sellerItem.accountNo = acctCtrl.text.trim();
                      sellerItem.ifsc = ifscCtrl.text.trim();
                      sellerItem.notes = notesCtrl.text.trim();
                      storage.updateSeller(sellerItem);
                    } else {
                      storage.addSeller(Seller(
                        id: 's-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        bankName: bankCtrl.text.trim(),
                        upiId: upiCtrl.text.trim(),
                        accountNo: acctCtrl.text.trim(),
                        ifsc: ifscCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordPayoutModal(BuildContext context, Seller seller, String currency) {
    final pending = seller.pendingBalance ?? (seller.totalSourcingCost - seller.totalPaid);
    final amountCtrl = TextEditingController(text: pending > 0 ? pending.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController();
    String method = 'GPay / UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 18,
            right: 18,
            top: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Supplier Payout: ${seller.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
              ),
              const SizedBox(height: 6),
              Text(
                'Current Pending Balance: $currency ${pending.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.neonAmber, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Payout Amount (Rs.) *'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: method,
                dropdownColor: AppTheme.surfaceLight,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'GPay / UPI', child: Text('GPay / PhonePe / UPI')),
                  DropdownMenuItem(value: 'Bank Transfer / IMPS', child: Text('Bank Transfer / IMPS')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                ],
                onChanged: (val) => setModalState(() => method = val ?? 'GPay / UPI'),
              ),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Txn ID')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                  child: const Text('Confirm Payout & Record Expense', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amt <= 0) return;
                    StorageService().recordSupplierPayout(
                      seller.id,
                      amt,
                      notes: '${notesCtrl.text.trim()} ($method)',
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recorded payout of Rs. ${amt.toStringAsFixed(0)} to ${seller.name}')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteBuyer(Buyer buyer, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Buyer?'),
        content: Text('Are you sure you want to delete ${buyer.name}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Delete'),
            onPressed: () {
              storage.deleteBuyer(buyer.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSeller(Seller seller, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to delete supplier ${seller.name}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Delete'),
            onPressed: () {
              storage.deleteSeller(seller.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
