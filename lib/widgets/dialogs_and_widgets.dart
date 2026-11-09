import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Fullscreen Image Zoom & Carousel Dialog
class ImagePreviewDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewDialog({Key? key, required this.images, this.initialIndex = 0}) : super(key: key);

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.92),
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: widget.images.length,
            onPageChanged: (idx) => setState(() => currentIndex = idx),
            itemBuilder: (ctx, idx) {
              final imgUrl = widget.images[idx];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: imgUrl.startsWith('http')
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              );
            },
          ),

          // Header with count and close
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Navigation Arrows if multiple photos
          if (widget.images.length > 1) ...[
            if (currentIndex > 0)
              Positioned(
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 30),
                  onPressed: () => pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
                ),
              ),
            if (currentIndex < widget.images.length - 1)
              Positioned(
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 30),
                  onPressed: () => pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports, size: 64, color: AppTheme.primaryBlue),
          SizedBox(height: 12),
          Text('Free Fire Account Screenshot', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Professional Invoice & Bill Receipt Dialog
class InvoiceReceiptDialog extends StatelessWidget {
  final Sale sale;
  final String storeName;
  final String storePhone;
  final String currency;

  const InvoiceReceiptDialog({
    Key? key,
    required this.sale,
    required this.storeName,
    required this.storePhone,
    required this.currency,
  }) : super(key: key);

  String get billText {
    final buffer = StringBuffer();
    buffer.writeln('===================================');
    buffer.writeln('     ★ $storeName ★');
    buffer.writeln('    OFFICIAL ID SALE INVOICE');
    buffer.writeln('===================================');
    buffer.writeln('Invoice No: #${sale.id}');
    buffer.writeln('Date: ${sale.date}');
    buffer.writeln('-----------------------------------');
    buffer.writeln('👤 BUYER: ${sale.buyerName} (${sale.buyerPhone})');
    buffer.writeln('🎮 ACCOUNT: ${sale.idName}');
    buffer.writeln('🆔 GAME UID: ${sale.uid}');
    buffer.writeln('-----------------------------------');
    buffer.writeln('Deal Price:      $currency ${sale.salePrice.toStringAsFixed(2)}');
    buffer.writeln('Amount Paid:     $currency ${sale.paidAmount.toStringAsFixed(2)}');
    buffer.writeln('Balance Due:     $currency ${sale.remainingDeo.toStringAsFixed(2)}');
    if (sale.remainingDeo > 0 && sale.dueDate.isNotEmpty) {
      buffer.writeln('Due Date:        ${sale.dueDate}');
    }
    buffer.writeln('Payment Method:  ${sale.paymentMethod}');
    if (sale.bankName.isNotEmpty) {
      buffer.writeln('Bank:            ${sale.bankName}');
    }
    if (sale.txnId.isNotEmpty) {
      buffer.writeln('Txn Ref:         ${sale.txnId}');
    }
    buffer.writeln('-----------------------------------');
    buffer.writeln('Thank you for trusting $storeName!');
    buffer.writeln('Contact: $storePhone');
    buffer.writeln('===================================');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isPartial = sale.remainingDeo > 0;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'OFFICIAL BILL RECEIPT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppTheme.dividerColor),

              // Store branding
              Center(
                child: Column(
                  children: [
                    Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Contact: $storePhone · Invoice #${sale.id}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer & Item details
              _buildBillRow('Buyer Name:', sale.buyerName, bold: true),
              _buildBillRow('Buyer Contact:', sale.buyerPhone.isNotEmpty ? sale.buyerPhone : 'N/A'),
              _buildBillRow('Free Fire ID:', sale.idName),
              _buildBillRow('Account UID:', sale.uid, bold: true),
              _buildBillRow('Sale Date:', sale.date),
              const Divider(color: AppTheme.dividerColor),

              // Pricing Breakdown
              _buildBillRow('Agreed Deal Price:', '$currency ${sale.salePrice.toStringAsFixed(2)}', color: AppTheme.primaryBlue),
              _buildBillRow('Amount Paid Upfront:', '$currency ${sale.paidAmount.toStringAsFixed(2)}', color: AppTheme.emeraldGreen),
              _buildBillRow('Remaining DEO / Due:', '$currency ${sale.remainingDeo.toStringAsFixed(2)}', color: isPartial ? AppTheme.amberWarning : AppTheme.textMuted, bold: isPartial),

              if (sale.remainingDeo > 0 && sale.dueDate.isNotEmpty)
                _buildBillRow('Balance Due Date:', sale.dueDate, color: AppTheme.roseRed),

              _buildBillRow('Payment Method:', sale.paymentMethod),
              if (sale.bankName.isNotEmpty) _buildBillRow('Bank:', sale.bankName),
              if (sale.txnId.isNotEmpty) _buildBillRow('Reference Txn ID:', sale.txnId),

              const SizedBox(height: 20),

              // Actions: WhatsApp & Copy
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('WhatsApp Bill'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.black),
                      onPressed: () async {
                        String phone = sale.buyerPhone.replaceAll(RegExp(r'[^0-9]'), '');
                        if (!phone.startsWith('91') && phone.length == 10) phone = '91$phone';
                        final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(billText)}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: billText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bill Receipt copied to clipboard!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Embedded Collapsible Calculator
class EmbeddedCalculatorWidget extends StatefulWidget {
  final Function(double) onUseResult;

  const EmbeddedCalculatorWidget({Key? key, required this.onUseResult}) : super(key: key);

  @override
  State<EmbeddedCalculatorWidget> createState() => _EmbeddedCalculatorWidgetState();
}

class _EmbeddedCalculatorWidgetState extends State<EmbeddedCalculatorWidget> {
  bool isExpanded = false;
  final num1Ctrl = TextEditingController();
  final num2Ctrl = TextEditingController();
  String selectedOp = '+';
  double result = 0.0;

  void calculate() {
    final a = double.tryParse(num1Ctrl.text) ?? 0.0;
    final b = double.tryParse(num2Ctrl.text) ?? 0.0;
    setState(() {
      switch (selectedOp) {
        case '+': result = a + b; break;
        case '−': result = a - b; break;
        case '×': result = a * b; break;
        case '÷': result = b != 0 ? a / b : 0.0; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_outlined, color: AppTheme.neonCyan, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Quick Calculator & Profit Tool',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(color: AppTheme.dividerColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: num1Ctrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Amount A'),
                          onChanged: (_) => calculate(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedOp,
                        dropdownColor: AppTheme.surface,
                        items: ['+', '−', '×', '÷'].map((op) => DropdownMenuItem(value: op, child: Text(op, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedOp = val);
                            calculate();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: num2Ctrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Amount B'),
                          onChanged: (_) => calculate(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '= Rs. ${result.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.emeraldGreen),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_downward, size: 14),
                        label: const Text('Use in Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => widget.onUseResult(result),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
