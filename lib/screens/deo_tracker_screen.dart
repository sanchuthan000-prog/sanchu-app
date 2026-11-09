import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String filterStatus = 'All Dues'; // 'All Dues' | 'Overdue Only' | 'Settled'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        final allDeos = storage.deoTracker;
        final settledCount = allDeos.where((d) => d.status == 'Settled').length;
        final overdueCount = allDeos.where((d) => d.status != 'Settled' && d.daysOverdue > 0).length;
        final totalOutstanding = allDeos.where((d) => d.status != 'Settled').fold(0.0, (acc, item) => acc + storage.calculateGrandTotalDue(item.id));

        final filteredDeos = allDeos.where((d) {
          if (filterStatus == 'Overdue Only') return d.status != 'Settled' && d.daysOverdue > 0;
          if (filterStatus == 'Settled') return d.status == 'Settled';
          return d.status != 'Settled'; // All active dues by default
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('DEO / Customer Due Tracker'),
            actions: [
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.neonCyan), onPressed: () => setState(() {})),
            ],
          ),
          body: Column(
            children: [
              // Summary Cards at Top
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
                    _buildSummaryTile('Total Outstanding', '$currency ${totalOutstanding.toStringAsFixed(0)}', AppTheme.roseRed),
                    Container(width: 1, height: 35, color: AppTheme.dividerColor),
                    _buildSummaryTile('Overdue Dues', '$overdueCount Accounts', AppTheme.amberWarning),
                    Container(width: 1, height: 35, color: AppTheme.dividerColor),
                    _buildSummaryTile('Settled Accounts', '$settledCount Cleared', AppTheme.emeraldGreen),
                  ],
                ),
              ),

              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: ['All Dues', 'Overdue Only', 'Settled'].map((tab) {
                    final isSelected = filterStatus == tab;
                    Color color = AppTheme.primaryBlue;
                    if (tab == 'Overdue Only') color = AppTheme.roseRed;
                    if (tab == 'Settled') color = AppTheme.emeraldGreen;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tab),
                        selected: isSelected,
                        onSelected: (_) => setState(() => filterStatus = tab),
                        backgroundColor: AppTheme.surfaceLight,
                        selectedColor: color.withOpacity(0.2),
                        checkmarkColor: color,
                        labelStyle: TextStyle(
                          color: isSelected ? color : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // DEO Cards
              Expanded(
                child: filteredDeos.isEmpty
                    ? const Center(child: Text('No DEO records in this view', style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDeos.length,
                        itemBuilder: (context, index) {
                          final deo = filteredDeos[index];
                          final linkedExtras = storage.extraPayments.where((e) => e.deoId == deo.id).toList();
                          final extrasTotal = linkedExtras.fold(0.0, (acc, item) => acc + item.amount);
                          final grandTotal = deo.remainingDeo + extrasTotal + deo.overdueFine;
                          final isOverdue = deo.daysOverdue > 0;
                          final isSettled = deo.status == 'Settled';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer Name & WhatsApp
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(deo.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Text('Account: ${deo.idName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.send, size: 14),
                                        label: const Text('WhatsApp Bill'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.emeraldGreen,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => WhatsAppService.sendDeoReminder(deo),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Financial Numbers
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
                                        _buildCol('Paid', '$currency ${deo.paidAmount.toStringAsFixed(0)}', AppTheme.emeraldGreen),
                                        _buildCol('ID Due', '$currency ${deo.remainingDeo.toStringAsFixed(0)}', AppTheme.amberWarning),
                                        _buildCol('Extras', '$currency ${extrasTotal.toStringAsFixed(0)}', AppTheme.neonCyan),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Due Date & Late fines
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Due: ${deo.dueDate.isNotEmpty ? deo.dueDate : "N/A"}${isOverdue ? " (${deo.daysOverdue} days late)" : ""}',
                                        style: TextStyle(color: isOverdue ? AppTheme.roseRed : AppTheme.textMuted, fontSize: 12, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                                      ),
                                      Text(
                                        'GRAND TOTAL: $currency ${grandTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.roseRed),
                                      ),
                                    ],
                                  ),

                                  // NESTED EXTRA PAYMENTS SECTION
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.cardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('EXTRA CHARGES (Top-ups, fees):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                            InkWell(
                                              onTap: () => _showAddExtraModal(context, deo),
                                              child: const Text('+ Add Extra Money', style: TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        if (linkedExtras.isEmpty)
                                          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('No extra charges', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)))
                                        else
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: linkedExtras.map((e) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text('${e.title}: Rs. ${e.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                                                      const SizedBox(width: 4),
                                                      InkWell(
                                                        onTap: () => storage.deleteExtraPayment(e.id),
                                                        child: const Icon(Icons.close, size: 12, color: AppTheme.roseRed),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Divider(color: AppTheme.dividerColor, height: 18),

                                  // Card Actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!isSettled)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.payment, size: 14),
                                          label: const Text('Update Money / Pay'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            textStyle: const TextStyle(fontSize: 11),
                                          ),
                                          onPressed: () => _showRecordPaymentModal(context, deo),
                                        ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppTheme.cardBorder),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        child: const Text('History', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                        onPressed: () => _showPaymentHistoryDialog(context, deo),
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

  Widget _buildSummaryTile(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  Widget _buildCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      ],
    );
  }

  void _showRecordPaymentModal(BuildContext context, DeoRecord deo) {
    final amountCtrl = TextEditingController(text: deo.remainingDeo.toStringAsFixed(0));
    final noteCtrl = TextEditingController();
    String method = 'GPay / UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 18, right: 18, top: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record Payment: ${deo.customerName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
            const SizedBox(height: 4),
            Text('Remaining ID Due: Rs. ${deo.remainingDeo.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Payment Amount Received (Rs.) *')),
            const SizedBox(height: 8),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Notes / Slip Reference')),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('SAVE PAYMENT'),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExtraModal(BuildContext context, DeoRecord deo) {
    String purpose = 'Top-up';
    final titleCtrl = TextEditingController(text: 'Weekly Diamond Pass Top-up');
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 18, right: 18, top: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Extra Money / Charges for ${deo.customerName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: purpose,
                dropdownColor: AppTheme.surfaceLight,
                items: ['Top-up', 'ID Expenses', 'Account Recovery', 'Other (Custom)'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) {
                  setModalState(() {
                    purpose = val ?? purpose;
                    if (purpose == 'Top-up') titleCtrl.text = 'Diamond Top-up';
                    if (purpose == 'ID Expenses') titleCtrl.text = 'Name change card expense';
                    if (purpose == 'Account Recovery') titleCtrl.text = 'Recovery fee';
                  });
                },
                decoration: const InputDecoration(labelText: 'Purpose'),
              ),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Custom Title / Description')),
              const SizedBox(height: 8),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Extra Amount (Rs.) *')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('ADD TO CUSTOMER DUE'),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amount <= 0 || titleCtrl.text.isEmpty) return;

                    StorageService().addExtraPayment(ExtraPayment(
                      id: 'ex-${DateTime.now().millisecondsSinceEpoch}',
                      deoId: deo.id,
                      buyerName: deo.customerName,
                      title: titleCtrl.text,
                      amount: amount,
                      date: DateTime.now().toIso8601String().substring(0, 10),
                    ));
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

  void _showPaymentHistoryDialog(BuildContext context, DeoRecord deo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Payment History: ${deo.customerName}'),
        content: SizedBox(
          width: 320,
          child: deo.payments.isEmpty
              ? const Text('No installment payments recorded yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: deo.payments.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.dividerColor),
                  itemBuilder: (c, i) {
                    final p = deo.payments[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('+Rs. ${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                      subtitle: Text('${p.date} · ${p.paymentMethod}${p.notes.isNotEmpty ? " (${p.notes})" : ""}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    );
                  },
                ),
        ),
        actions: [TextButton(child: const Text('Close'), onPressed: () => Navigator.pop(ctx))],
      ),
    );
  }
}
