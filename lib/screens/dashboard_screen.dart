import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs_and_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;
  final VoidCallback onOpenAddId;
  final VoidCallback onOpenRecordSale;

  const DashboardScreen({
    Key? key,
    required this.onNavigateTab,
    required this.onOpenAddId,
    required this.onOpenRecordSale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;
        final nowFormatted = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

        // Find Overdue Customer DEOs for Urgent Alerts
        final overdueDeos = storage.deoTracker.where((d) => d.status != 'Settled' && d.daysOverdue > 0).toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Top Gaming Banner
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppTheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.primaryBlue),
                                  ),
                                  child: const Icon(Icons.sports_esports, color: AppTheme.neonCyan, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storage.settings.storeName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary, letterSpacing: 0.5),
                                    ),
                                    Text(
                                      nowFormatted,
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.emeraldGreen, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text('ONLINE', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 PRIMARY EXECUTIVE KPI TILES
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.45,
                        children: [
                          _buildKpiCard(
                            'Stock Accounts',
                            '${storage.stockAccountsCount} IDs',
                            'Available in store',
                            Icons.shield_outlined,
                            AppTheme.neonCyan,
                            () => onNavigateTab(1),
                          ),
                          _buildKpiCard(
                            'Total Sales Revenue',
                            '$currency ${storage.totalSalesRevenue.toStringAsFixed(0)}',
                            '${storage.soldAccountsCount} Accounts Sold',
                            Icons.shopping_bag_outlined,
                            AppTheme.emeraldGreen,
                            () => onNavigateTab(2),
                          ),
                          _buildKpiCard(
                            'Pending Customer DEO',
                            '$currency ${storage.pendingCustomerDeo.toStringAsFixed(0)}',
                            'Credit receivable',
                            Icons.schedule,
                            AppTheme.amberWarning,
                            () => onNavigateTab(3),
                          ),
                          _buildKpiCard(
                            'Pending Supplier Dues',
                            '$currency ${storage.pendingSupplierDues.toStringAsFixed(0)}',
                            'Pay to sellers',
                            Icons.storefront_outlined,
                            AppTheme.roseRed,
                            () => onNavigateTab(5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // QUICK ACTIONS BAR
                      const Text('QUICK ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('+ Add ID'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                              onPressed: onOpenAddId,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.flash_on, size: 16),
                              label: const Text('+ Quick Sale'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.black),
                              onPressed: onOpenRecordSale,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance_wallet, size: 16),
                              label: const Text('Money'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: AppTheme.textPrimary),
                              onPressed: () => onNavigateTab(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // URGENT OVERDUE BALANCE ALERTS (If any)
                      if (overdueDeos.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.roseRed, size: 20),
                            const SizedBox(width: 6),
                            const Text('URGENT BALANCE ALERTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.roseRed, letterSpacing: 1.0)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...overdueDeos.map((deo) {
                          final totalDue = storage.calculateGrandTotalDue(deo.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.roseRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.roseRed.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(deo.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${deo.daysOverdue} days late · Account: ${deo.idName}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('$currency ${totalDue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.roseRed, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.send, color: AppTheme.emeraldGreen, size: 20),
                                      onPressed: () => WhatsAppService.sendDeoReminder(deo),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 18),
                      ],

                      // RECENT SALES PREVIEW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('RECENT COMPLETED DEALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.8)),
                          GestureDetector(
                            onTap: () => onNavigateTab(2),
                            child: const Text('View All >', style: TextStyle(color: AppTheme.neonCyan, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (storage.sales.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No sales recorded yet', style: TextStyle(color: AppTheme.textMuted))))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: storage.sales.take(3).length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final s = storage.sales[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.idName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 3),
                                        Text('Buyer: ${s.buyerName} · ${s.paymentMethod}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$currency ${s.salePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
                                      Text('+Rs. ${s.profit.toStringAsFixed(0)} profit', style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String val, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
