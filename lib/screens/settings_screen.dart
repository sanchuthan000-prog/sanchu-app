import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static Future<void> exportJsonBackup(BuildContext context) async {
    final storage = StorageService();
    final snapshot = storage.exportFullSnapshot();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(snapshot);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final fileName = 'alone_id_sale_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/json', name: fileName)],
        text: 'ALONE ID SALE - Full Database Backup (.json)',
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: jsonStr));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON Backup copied to clipboard!')),
      );
    }
  }

  static void showImportJsonDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    final storage = StorageService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: AppTheme.neonAmber),
            SizedBox(width: 8),
            Text('Import JSON Backup', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your exported JSON backup text below to restore all IDs, Customers, Sales, and Accounts:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonCtrl,
                maxLines: 7,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '{\n  id: main,\n  data: {\n    ids: [...],\n    buyers: [...]\n  }\n}',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.paste, size: 14),
                    label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 11)),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        jsonCtrl.text = data!.text!;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonAmber, foregroundColor: Colors.black),
            child: const Text('RESTORE DATA', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              final raw = jsonCtrl.text.trim();
              if (raw.isEmpty) return;
              try {
                final parsed = jsonDecode(raw);
                storage.loadFromJson(parsed);
                storage.saveToLocal();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All IDs, Customers & Sales restored successfully!'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid JSON format: '),
                    backgroundColor: AppTheme.roseRed,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static void showViewJsonDialog(BuildContext context) {
    final storage = StorageService();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(storage.exportFullSnapshot());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Current Database JSON', style: TextStyle(fontSize: 15)),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textSecondary),
            ),
          ),
        ),
        actions: [
          TextButton(child: const Text('Close'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('Copy JSON'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan, foregroundColor: Colors.black),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Backup, JSON & Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Store Profile Card
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
                    const Text('BUSINESS PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryCyan)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.store, color: AppTheme.primaryCyan),
                      title: Text(storage.settings.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Phone:  · Currency: '),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.textMuted),
                        onPressed: () => _editStoreProfile(context, storage),
                      ),
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppTheme.neonGreen, size: 16),
                        const SizedBox(width: 8),
                        Text('Authorized Owner: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Database Overview Summary
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
                    const Text('DATABASE CONTENTS OVERVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonCyan)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip('🎮 ${storage.ids.length} Free Fire IDs', AppTheme.primaryBlue),
                        _buildStatChip('👥 ${storage.buyers.length} Customers / Buyers', AppTheme.emeraldGreen),
                        _buildStatChip('🏬 ${storage.sellers.length} Suppliers / Sellers', AppTheme.neonAmber),
                        _buildStatChip('🛒 ${storage.sales.length} Sales Deals', AppTheme.emeraldGreen),
                        _buildStatChip('⏰ ${storage.deoTracker.length} DEO Credits', AppTheme.roseRed),
                        _buildStatChip('💵 ${storage.moneyEntries.length} Money Entries', AppTheme.neonCyan),
                        _buildStatChip('🔒 ${storage.binds.length} Account Binds', AppTheme.primaryBlue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // JSON Export & Restore Card (Primary)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonAmber.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.folder_zip, color: AppTheme.neonAmber),
                        SizedBox(width: 8),
                        Text('JSON FILE BACKUP & RESTORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.neonAmber)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export all Free Fire IDs, Customers, Suppliers, Sales, DEO, and Personal Money into a single .json backup file.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Primary Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('EXPORT FILE'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => SettingsScreen.exportJsonBackup(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('IMPORT JSON'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonAmber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => SettingsScreen.showImportJsonDialog(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Secondary Tools Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('Copy JSON Text'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textPrimary),
                            onPressed: () {
                              final jsonStr = jsonEncode(storage.exportFullSnapshot());
                              Clipboard.setData(ClipboardData(text: jsonStr));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Full database JSON copied to clipboard!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('View Raw JSON'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.neonCyan),
                            onPressed: () => SettingsScreen.showViewJsonDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cloud Snapshot Sync Status
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
                    const Row(
                      children: [
                        Icon(Icons.cloud_done, color: AppTheme.neonGreen, size: 18),
                        SizedBox(width: 8),
                        Text('LOCAL STORAGE SNAPSHOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonGreen)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Auto-Save Status: ${storage.syncStatus}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Last Saved: ${storage.lastSyncTime != null ? storage.lastSyncTime.toString().substring(0, 19) : "Active"}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('SAVE SNAPSHOT TO DEVICE NOW'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: AppTheme.textPrimary),
                        onPressed: () async {
                          await storage.saveToLocal();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All stores successfully saved to device storage!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _editStoreProfile(BuildContext context, StorageService storage) {
    final nameCtrl = TextEditingController(text: storage.settings.storeName);
    final phoneCtrl = TextEditingController(text: storage.settings.storePhone);
    final currCtrl = TextEditingController(text: storage.settings.currencySymbol);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Store Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone')),
            const SizedBox(height: 10),
            TextField(controller: currCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol (Rs., $, etc.)')),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              storage.settings.storeName = nameCtrl.text;
              storage.settings.storePhone = phoneCtrl.text;
              storage.settings.currencySymbol = currCtrl.text;
              storage.saveToLocal();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
