import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_theme.dart';

class DeoTrackerScreen extends StatefulWidget {
  const DeoTrackerScreen({Key? key}) : super(key: key);

  @override
  State<DeoTrackerScreen> createState() => _DeoTrackerScreenState();
}

class _DeoTrackerScreenState extends State<DeoTrackerScreen> {
  String filterStatus = 'Active'; // 'All' | 'Active' | 'Settled'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        final deos = storage.deoTracker.where((d) {
          if (filterStatus == 'Active') return d.status != 'Settled';
          if (filterStatus == 'Settled') return d.status == 'Settled';
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('DEO Customer Ledger'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primaryCyan),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ['Active', 'Settled', 'All'].map((status) {
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
              ),

              // DEO Cards List
              Expanded(
                child: deos.isEmpty
                    ? const Center(
                        child: Text('No DEO records found', style: TextStyle(color: AppTheme.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: deos.length,
                        itemBuilder: (context, index) {
                          final deo = deos[index];
                          final linkedExtras = storage.extraPayments.where((e) => e.deoId == deo.id).toList();
                          final extrasTotal = linkedExtras.fold(0.0, (sum, item) => sum + item.amount);
                          final grandTotalDue = deo.remainingDeo + extrasTotal;
                          final isSettled = deo.status == 'Settled';

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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              deo.customerName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Account: ${deo.idName}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSettled ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.neonRed.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isSettled ? AppTheme.neonGreen : AppTheme.neonRed),
                                        ),
                                        child: Text(
                                          isSettled ? 'SETTLED' : 'DUE',
                                          style: TextStyle(
                                            color: isSettled ? AppTheme.neonGreen : AppTheme.neonRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Financial Breakdown Row
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildCol('Total Deal', '$currency ${deo.totalAmount.toStringAsFixed(0)}', AppTheme.textSecondary),
                                        _buildCol('Paid', '$currency ${deo.paidAmount.toStringAsFixed(0)}', AppTheme.neonGreen),
                                        _buildCol('ID Due', '$currency ${deo.remainingDeo.toStringAsFixed(0)}', AppTheme.neonAmber),
                                        _buildCol('Extras', '$currency ${extrasTotal.toStringAsFixed(0)}', AppTheme.primaryCyan),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Grand Total Due Highlight
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Due Date: ${deo.dueDate.isNotEmpty ? deo.dueDate : "N/A"}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                      Text(
                                        'GRAND TOTAL: $currency ${grandTotalDue.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.neonRed,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Extras itemized preview
                                  if (linkedExtras.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: linkedExtras.map((e) => Chip(
                                        backgroundColor: AppTheme.cardBg,
                                        label: Text('${e.title}: $currency ${e.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                      )).toList(),
                                    ),
                                  ],

                                  const Divider(color: AppTheme.dividerColor, height: 18),

                                  // Action Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // WhatsApp Reminder Button
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.send, size: 14),
                                        label: const Text('WhatsApp Reminder'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.neonGreen,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () async {
                                          final sent = await WhatsAppService.sendDeoReminder(deo);
                                          if (!sent && mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Could not launch WhatsApp. Please check customer phone number.')),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),

                                      // Record Payment Button
                                      if (!isSettled)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.payment, size: 14),
                                          label: const Text('Pay Due'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryCyan,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () => _showRecordPaymentDialog(context, deo),
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
        );
      },
    );
  }

  Widget _buildCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  void _showRecordPaymentDialog(BuildContext context, DeoRecord deo) {
    final amountCtrl = TextEditingController(text: deo.remainingDeo.toStringAsFixed(0));
    final noteCtrl = TextEditingController();
    String method = 'GPay / UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Installment: ${deo.customerName}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
            ),
            const SizedBox(height: 4),
            Text('Account: ${deo.idName} · Remaining ID Due: Rs. ${deo.remainingDeo.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Paid (Rs.)')),
            const SizedBox(height: 10),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Payment Note / Receipt No.')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('SUBMIT PAYMENT'),
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                  if (amount <= 0) return;

                  final payment = DeoPayment(
                    id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
                    amount: amount,
                    date: DateTime.now().toIso8601String().substring(0, 10),
                    paymentMethod: method,
                    notes: noteCtrl.text,
                  );

                  StorageService().addDeoPayment(deo.id, payment);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment of Rs. ${amount.toStringAsFixed(0)} recorded!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
