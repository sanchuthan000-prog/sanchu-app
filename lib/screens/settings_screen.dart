import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
            title: const Text('Settings & Cloud Backup'),
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
                      subtitle: Text('Phone: ${storage.settings.storePhone} · Currency: ${storage.settings.currencySymbol}'),
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
                        Text('Authorized Owner: ${storage.settings.ownerEmail}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                        Text('CLOUD SNAPSHOT (id = main)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonGreen)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Status: ${storage.syncStatus}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Last Saved: ${storage.lastSyncTime != null ? storage.lastSyncTime.toString().substring(0, 19) : "Just now"}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('SYNC SNAPSHOT NOW'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan),
                        onPressed: () async {
                          await storage.saveToLocal();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All 9 stores successfully saved to main snapshot!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // JSON Export & Restore Card
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
                    const Text('DATA BACKUP & RESTORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonAmber)),
                    const SizedBox(height: 6),
                    const Text('Export or import full database snapshot (all 9 business stores in JSON format).', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('EXPORT JSON'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: AppTheme.textPrimary),
                            onPressed: () {
                              final jsonStr = jsonEncode(storage.exportFullSnapshot());
                              Clipboard.setData(ClipboardData(text: jsonStr));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('JSON Backup copied to clipboard! You can paste and save it safely.')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload, size: 16),
                            label: const Text('IMPORT JSON'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: AppTheme.textPrimary),
                            onPressed: () => _showImportJsonDialog(context, storage),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            TextField(controller: currCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol (Rs., \$, etc.)')),
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

  void _showImportJsonDialog(BuildContext context, StorageService storage) {
    final jsonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Import Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your exported JSON backup text below:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 10),
            TextField(
              controller: jsonCtrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '{"id":"main","data":{...}}'),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonAmber, foregroundColor: Colors.black),
            child: const Text('RESTORE DATA'),
            onPressed: () {
              try {
                final parsed = jsonDecode(jsonCtrl.text);
                storage.loadFromJson(parsed);
                storage.saveToLocal();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup restored successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid JSON format: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
