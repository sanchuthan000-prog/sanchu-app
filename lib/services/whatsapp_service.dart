import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import 'storage_service.dart';

class WhatsAppService {
  static String generateDeoReminderText({
    required DeoRecord deo,
    required List<ExtraPayment> extras,
    required String storeName,
    required String currency,
  }) {
    final double extraSum = extras.fold(0.0, (acc, item) => acc + item.amount);
    final double grandTotal = deo.remainingDeo + extraSum;

    final buffer = StringBuffer();
    buffer.writeln('🔥 *REMINDER: FREE FIRE ID PAYMENT DUE* 🔥');
    buffer.writeln('Store: *$storeName*');
    buffer.writeln('-----------------------------------');
    buffer.writeln('👤 *Customer:* ${deo.customerName}');
    buffer.writeln('🎮 *Account:* ${deo.idName}');
    buffer.writeln('💰 *ID Remaining Due:* $currency ${deo.remainingDeo.toStringAsFixed(0)}');

    if (extras.isNotEmpty) {
      buffer.writeln('\n📋 *Extra Services / Charges:*');
      for (var e in extras) {
        buffer.writeln('  • ${e.title}: $currency ${e.amount.toStringAsFixed(0)}');
      }
      buffer.writeln('➕ *Extras Total:* $currency ${extraSum.toStringAsFixed(0)}');
    }

    buffer.writeln('-----------------------------------');
    buffer.writeln('⚡ *GRAND TOTAL DUE:* *$currency ${grandTotal.toStringAsFixed(0)}*');
    buffer.writeln('📅 *Due Date:* ${deo.dueDate.isNotEmpty ? deo.dueDate : "Immediate"}');
    buffer.writeln('-----------------------------------');
    buffer.writeln('Kindly clear the balance to maintain clean account status and future deals.');
    buffer.writeln('Thank you for choosing *$storeName*!');

    return buffer.toString();
  }

  static Future<bool> sendDeoReminder(DeoRecord deo) async {
    final storage = StorageService();
    final customerExtras = storage.extraPayments.where((e) => e.deoId == deo.id).toList();

    final message = generateDeoReminderText(
      deo: deo,
      extras: customerExtras,
      storeName: storage.settings.storeName,
      currency: storage.settings.currencySymbol,
    );

    String phone = deo.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('91') && phone.length == 10) {
      phone = '91$phone';
    }

    final urlString = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      // Fallback
    }
    return false;
  }
}
