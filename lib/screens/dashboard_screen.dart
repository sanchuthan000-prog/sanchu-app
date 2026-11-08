import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({Key? key, required this.onNavigateTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on, color: AppTheme.primaryCyan, size: 20),
                ),
                const SizedBox(width: 10),
                Text(storage.settings.storeName),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.neonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      storage.syncStatus,
                      style: const TextStyle(fontSize: 11, color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Action Buttons Bar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('NEW SALE'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan),
                        onPressed: () => onNavigateTab(2), // Jump to Sales tab
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: const Text('ADD ID'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonAmber, foregroundColor: Colors.black),
                        onPressed: () => onNavigateTab(1), // Jump to IDs tab
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SECTION 1: BUSINESS OVERVIEW
                const Text(
                  'BUSINESS OVERVIEW',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryCyan,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Free Fire IDs', '${storage.totalFreeFireIds}', Icons.sports_esports, AppTheme.primaryCyan),
                    _buildStatCard('Available IDs', '${storage.availableIds}', Icons.check_circle_outline, AppTheme.neonGreen),
                    _buildStatCard('Sold IDs', '${storage.soldIds}', Icons.sell_outlined, AppTheme.accentPurple),
                    _buildStatCard('Total Sales', '$currency ${storage.totalSalesVolume.toStringAsFixed(0)}', Icons.payments_outlined, AppTheme.primaryCyan),
                    _buildStatCard('Total Investment', '$currency ${storage.totalInvestment.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined, AppTheme.textSecondary),
                    _buildStatCard('Total Profit', '$currency ${storage.totalSalesProfit.toStringAsFixed(0)}', Icons.trending_up, AppTheme.neonGreen),
                    _buildStatCard('Outstanding Balance', '$currency ${storage.totalOutstandingBalance.toStringAsFixed(0)}', Icons.pending_actions, AppTheme.neonAmber),
                    _buildStatCard('Total DEO Balance', '$currency ${storage.totalDeoBalance.toStringAsFixed(0)}', Icons.schedule, AppTheme.neonRed),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION 2: PERSONAL MONEY MANAGEMENT (Isolated)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_outline, color: AppTheme.neonGreen, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'PERSONAL MONEY & PROFIT',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: AppTheme.neonGreen,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => onNavigateTab(4), // Money tab
                            child: const Text('View All >', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMoneyMetric(
                              'Personal Income',
                              '$currency ${storage.totalPersonalIncome.toStringAsFixed(0)}',
                              AppTheme.neonGreen,
                              Icons.arrow_upward,
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppTheme.dividerColor),
                          Expanded(
                            child: _buildMoneyMetric(
                              'Personal Expense',
                              '$currency ${storage.totalPersonalExpense.toStringAsFixed(0)}',
                              AppTheme.neonRed,
                              Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.dividerColor, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Personal Balance:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          Text(
                            '$currency ${storage.netPersonalBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: storage.netPersonalBalance >= 0 ? AppTheme.neonGreen : AppTheme.neonRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Sales Feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECENT SALES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                    GestureDetector(
                      onTap: () => onNavigateTab(2),
                      child: const Text('See All', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (storage.sales.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: const Text('No sales recorded yet', style: TextStyle(color: AppTheme.textMuted)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: storage.sales.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = storage.sales[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.idName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Buyer: ${s.buyerName} · ${s.paymentMethod}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$currency ${s.salePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
                                const SizedBox(height: 4),
                                Text(
                                  '+$currency ${s.profit.toStringAsFixed(0)} profit',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
                                ),
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
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyMetric(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
