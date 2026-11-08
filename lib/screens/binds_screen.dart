import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BindsScreen extends StatefulWidget {
  const BindsScreen({Key? key}) : super(key: key);

  @override
  State<BindsScreen> createState() => _BindsScreenState();
}

class _BindsScreenState extends State<BindsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Binds & Account Security'),
          ),
          body: storage.binds.isEmpty
              ? const Center(
                  child: Text('No security bind records found', style: TextStyle(color: AppTheme.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: storage.binds.length,
                  itemBuilder: (context, index) {
                    final bind = storage.binds[index];
                    final isSecure = bind.status.toLowerCase() == 'secure';

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
                                    bind.idName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSecure ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.neonAmber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSecure ? AppTheme.neonGreen : AppTheme.neonAmber),
                                  ),
                                  child: Text(
                                    bind.status.toUpperCase(),
                                    style: TextStyle(
                                      color: isSecure ? AppTheme.neonGreen : AppTheme.neonAmber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Bind details
                            Text('Primary Gmail: ${bind.gmail}', style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Recovery Email: ${bind.recoveryEmail.isNotEmpty ? bind.recoveryEmail : "Not set"}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Cooldown Date: ${bind.cooldownDate.isNotEmpty ? bind.cooldownDate : "Clean / No Cooldown"}', style: const TextStyle(color: AppTheme.neonAmber, fontSize: 12)),
                            const Divider(color: AppTheme.dividerColor, height: 20),

                            // 5-Point Security Checklist
                            const Text('SECURITY CHECKLIST:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            const SizedBox(height: 6),
                            _buildCheckRow('2-Step Verification Active', bind.securityChecklist['twoFactorOn'] == true, (val) {
                              setState(() => bind.securityChecklist['twoFactorOn'] = val);
                              storage.saveToLocal();
                            }),
                            _buildCheckRow('Recovery Phone Removed / Updated', bind.securityChecklist['recoveryPhoneRemoved'] == true, (val) {
                              setState(() => bind.securityChecklist['recoveryPhoneRemoved'] = val);
                              storage.saveToLocal();
                            }),
                            _buildCheckRow('Signed Out of Other Devices', bind.securityChecklist['signedOutOfDevices'] == true, (val) {
                              setState(() => bind.securityChecklist['signedOutOfDevices'] = val);
                              storage.saveToLocal();
                            }),
                            _buildCheckRow('8-Digit Backup Codes Saved', bind.securityChecklist['backupCodesSaved'] == true, (val) {
                              setState(() => bind.securityChecklist['backupCodesSaved'] = val);
                              storage.saveToLocal();
                            }),
                            _buildCheckRow('Buyer Verification Completed', bind.securityChecklist['buyerVerified'] == true, (val) {
                              setState(() => bind.securityChecklist['buyerVerified'] = val);
                              storage.saveToLocal();
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildCheckRow(String label, bool isChecked, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isChecked ? AppTheme.neonGreen : AppTheme.textMuted,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isChecked ? AppTheme.textPrimary : AppTheme.textMuted,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Switch(
            value: isChecked,
            activeColor: AppTheme.neonGreen,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
