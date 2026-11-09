import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BindsScreen extends StatefulWidget {
  const BindsScreen({Key? key}) : super(key: key);

  @override
  State<BindsScreen> createState() => _BindsScreenState();
}

class _BindsScreenState extends State<BindsScreen> {
  String searchQuery = '';
  String filterStatus = 'All'; // 'All' | 'Secure' | 'Cooldown' | 'Vulnerable' | 'Pending'
  final Map<String, bool> _obscurePasswords = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();

        // Filter binds
        final filteredBinds = storage.binds.where((b) {
          final query = searchQuery.toLowerCase();
          final matchesQuery = b.idName.toLowerCase().contains(query) ||
              b.uid.toLowerCase().contains(query) ||
              b.currentBind.toLowerCase().contains(query) ||
              b.recoveryEmail.toLowerCase().contains(query);

          final matchesFilter = filterStatus == 'All' || b.status.toLowerCase() == filterStatus.toLowerCase();
          return matchesQuery && matchesFilter;
        }).toList();

        // Summary Counts
        final totalBinds = storage.binds.length;
        final secureCount = storage.binds.where((b) => b.status.toLowerCase() == 'secure').length;
        final cooldownCount = storage.binds.where((b) => b.status.toLowerCase() == 'cooldown').length;
        final vulnerableCount = storage.binds.where((b) => b.status.toLowerCase() == 'vulnerable').length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Account Binds & Security'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_moderator, color: AppTheme.neonCyan),
                tooltip: 'Add Security Bind',
                onPressed: () => _showAddEditBindModal(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary KPI Bar
              Container(
                color: AppTheme.surfaceLight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    _buildSummaryItem('Total Binds', '$totalBinds', AppTheme.primaryCyan),
                    const SizedBox(width: 8),
                    _buildSummaryItem('Secured', '$secureCount', AppTheme.emeraldGreen),
                    const SizedBox(width: 8),
                    _buildSummaryItem('Cooldown', '$cooldownCount', AppTheme.neonAmber),
                    const SizedBox(width: 8),
                    _buildSummaryItem('Vulnerable', '$vulnerableCount', AppTheme.roseRed),
                  ],
                ),
              ),

              // Search & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                        hintText: 'Search by Account Name, UID, Linked Email...',
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Secure', 'Cooldown', 'Vulnerable', 'Pending'].map((status) {
                          final isSelected = filterStatus.toLowerCase() == status.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) => setState(() => filterStatus = status),
                              selectedColor: AppTheme.primaryCyan.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Binds List
              Expanded(
                child: filteredBinds.isEmpty
                    ? const Center(
                        child: Text('No matching security bind records found', style: TextStyle(color: AppTheme.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredBinds.length,
                        itemBuilder: (context, index) {
                          final bind = filteredBinds[index];
                          return _buildBindCard(bind, storage);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryCyan,
            icon: const Icon(Icons.shield, color: Colors.black),
            label: const Text('Add Bind Record', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () => _showAddEditBindModal(context),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
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
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildBindCard(BindRecord bind, StorageService storage) {
    final statusColor = _getStatusColor(bind.status);
    final obscure = _obscurePasswords[bind.id] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Title & Badges Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bind.idName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (bind.uid.isNotEmpty)
                        Text('UID: ${bind.uid}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                // Bind Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getBindTypeIcon(bind.bindType), size: 12, color: AppTheme.primaryCyan),
                      const SizedBox(width: 4),
                      Text(bind.bindType, style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    bind.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Credentials Detail Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildCredentialRow('Login Bind', bind.currentBind, Icons.account_circle_outlined, copyable: true),
                  if (bind.password.isNotEmpty) ...[
                    const Divider(color: AppTheme.dividerColor, height: 12),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        const Text('Password: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Expanded(
                          child: Text(
                            obscure ? '••••••••••••' : bind.password,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 16, color: AppTheme.textMuted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _obscurePasswords[bind.id] = !obscure),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 14, color: AppTheme.primaryCyan),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _copyToClipboard(bind.password, 'Password copied'),
                        ),
                      ],
                    ),
                  ],
                  if (bind.recoveryEmail.isNotEmpty) ...[
                    const Divider(color: AppTheme.dividerColor, height: 12),
                    _buildCredentialRow('Recovery Email', bind.recoveryEmail, Icons.email_outlined, copyable: true),
                  ],
                  if (bind.recoveryPhone.isNotEmpty) ...[
                    const Divider(color: AppTheme.dividerColor, height: 12),
                    _buildCredentialRow('Recovery Phone', bind.recoveryPhone, Icons.phone_android_outlined, copyable: true),
                  ],
                  if (bind.backupCodes.isNotEmpty) ...[
                    const Divider(color: AppTheme.dividerColor, height: 12),
                    _buildCredentialRow('2FA Backup Codes', bind.backupCodes, Icons.key_outlined, copyable: true),
                  ],
                  if (bind.cooldownDate.isNotEmpty) ...[
                    const Divider(color: AppTheme.dividerColor, height: 12),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppTheme.neonAmber),
                        const SizedBox(width: 6),
                        const Text('Cooldown End: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Expanded(
                          child: Text(
                            '${bind.cooldownDate} (${_calculateCooldownRemaining(bind.cooldownDate)})',
                            style: const TextStyle(fontSize: 11, color: AppTheme.neonAmber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5-Point Security Checklist
            const Text('5-POINT SECURITY CHECKLIST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            _buildCheckRow('1. 2-Step Verification Active', bind.securityChecklist['twoFactorOn'] == true, (val) {
              setState(() => bind.securityChecklist['twoFactorOn'] = val);
              storage.saveToLocal();
            }),
            _buildCheckRow('2. Recovery Phone Removed / Updated', bind.securityChecklist['recoveryPhoneRemoved'] == true, (val) {
              setState(() => bind.securityChecklist['recoveryPhoneRemoved'] = val);
              storage.saveToLocal();
            }),
            _buildCheckRow('3. Signed Out of All Previous Devices', bind.securityChecklist['signedOutOfDevices'] == true, (val) {
              setState(() => bind.securityChecklist['signedOutOfDevices'] = val);
              storage.saveToLocal();
            }),
            _buildCheckRow('4. 8-Digit Backup Codes Saved', bind.securityChecklist['backupCodesSaved'] == true, (val) {
              setState(() => bind.securityChecklist['backupCodesSaved'] = val);
              storage.saveToLocal();
            }),
            _buildCheckRow('5. Buyer Verification & Handover Done', bind.securityChecklist['buyerVerified'] == true, (val) {
              setState(() => bind.securityChecklist['buyerVerified'] = val);
              storage.saveToLocal();
            }),

            const Divider(color: AppTheme.dividerColor, height: 16),

            // Card Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.roseRed),
                  label: const Text('Delete', style: TextStyle(color: AppTheme.roseRed, fontSize: 12)),
                  onPressed: () => _confirmDelete(bind, storage),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.edit, size: 14, color: Colors.black),
                  label: const Text('Edit Bind Details', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddEditBindModal(context, bindItem: bind),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon, {bool copyable = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (copyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 14, color: AppTheme.primaryCyan),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Copy',
            onPressed: () => _copyToClipboard(value, '$label copied to clipboard'),
          ),
      ],
    );
  }

  Widget _buildCheckRow(String label, bool isChecked, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isChecked ? AppTheme.emeraldGreen : AppTheme.textMuted,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isChecked ? AppTheme.textPrimary : AppTheme.textMuted,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Switch(
            value: isChecked,
            activeColor: AppTheme.emeraldGreen,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'secure':
        return AppTheme.emeraldGreen;
      case 'cooldown':
        return AppTheme.neonAmber;
      case 'vulnerable':
        return AppTheme.roseRed;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getBindTypeIcon(String bindType) {
    switch (bindType.toLowerCase()) {
      case 'gmail':
        return Icons.mail;
      case 'facebook':
        return Icons.facebook;
      case 'twitter (x)':
      case 'twitter':
        return Icons.tag;
      case 'vk':
        return Icons.public;
      case 'apple id':
        return Icons.apple;
      default:
        return Icons.vpn_key;
    }
  }

  String _calculateCooldownRemaining(String cooldownDate) {
    try {
      final end = DateTime.parse(cooldownDate);
      final diff = end.difference(DateTime.now()).inDays;
      if (diff <= 0) return 'Cooldown Expired / Clean';
      return '$diff days left';
    } catch (_) {
      return cooldownDate;
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
  }

  void _showAddEditBindModal(BuildContext context, {BindRecord? bindItem}) {
    final isEdit = bindItem != null;
    final storage = StorageService();

    final idNameCtrl = TextEditingController(text: bindItem?.idName ?? '');
    final uidCtrl = TextEditingController(text: bindItem?.uid ?? '');
    String bindType = bindItem?.bindType ?? 'Gmail';
    final currentBindCtrl = TextEditingController(text: bindItem?.currentBind ?? '');
    final passwordCtrl = TextEditingController(text: bindItem?.password ?? '');
    final recoveryEmailCtrl = TextEditingController(text: bindItem?.recoveryEmail ?? '');
    final recoveryPhoneCtrl = TextEditingController(text: bindItem?.recoveryPhone ?? '');
    final backupCodesCtrl = TextEditingController(text: bindItem?.backupCodes ?? '');
    final cooldownDateCtrl = TextEditingController(text: bindItem?.cooldownDate ?? '');
    String status = bindItem?.status ?? 'Secure';

    // Free Fire ID selection
    String? selectedIdId = bindItem?.idRecordId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Account Bind' : 'Add New Account Bind',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Link to Inventory ID
                  if (storage.ids.isNotEmpty && !isEdit) ...[
                    DropdownButtonFormField<String>(
                      value: selectedIdId,
                      dropdownColor: AppTheme.surfaceLight,
                      decoration: const InputDecoration(labelText: 'Select Inventory ID (Optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Custom / Manual ID')),
                        ...storage.ids.map((id) => DropdownMenuItem(value: id.id, child: Text('${id.name} (${id.uid})'))),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedIdId = val;
                          if (val != null) {
                            final found = storage.ids.firstWhere((e) => e.id == val);
                            idNameCtrl.text = found.name;
                            uidCtrl.text = found.uid;
                            if (found.currentGmail.isNotEmpty) currentBindCtrl.text = found.currentGmail;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  TextField(controller: idNameCtrl, decoration: const InputDecoration(labelText: 'Account Title *')),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(child: TextField(controller: uidCtrl, decoration: const InputDecoration(labelText: 'Free Fire UID'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: bindType,
                          dropdownColor: AppTheme.surfaceLight,
                          decoration: const InputDecoration(labelText: 'Bind Platform'),
                          items: const [
                            DropdownMenuItem(value: 'Gmail', child: Text('Gmail')),
                            DropdownMenuItem(value: 'Facebook', child: Text('Facebook')),
                            DropdownMenuItem(value: 'Twitter (X)', child: Text('Twitter (X)')),
                            DropdownMenuItem(value: 'VK', child: Text('VK')),
                            DropdownMenuItem(value: 'Apple ID', child: Text('Apple ID')),
                          ],
                          onChanged: (val) => setModalState(() => bindType = val ?? 'Gmail'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(controller: currentBindCtrl, decoration: const InputDecoration(labelText: 'Login ID / Email / Username *')),
                  const SizedBox(height: 8),

                  TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password (Optional)')),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(child: TextField(controller: recoveryEmailCtrl, decoration: const InputDecoration(labelText: 'Recovery Email'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: recoveryPhoneCtrl, decoration: const InputDecoration(labelText: 'Recovery Phone'))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: backupCodesCtrl,
                    decoration: const InputDecoration(labelText: '2FA Backup Codes (Comma-separated)'),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cooldownDateCtrl,
                          decoration: InputDecoration(
                            labelText: 'Cooldown Date (YYYY-MM-DD)',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (d != null) {
                                  cooldownDateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          dropdownColor: AppTheme.surfaceLight,
                          decoration: const InputDecoration(labelText: 'Security Status'),
                          items: const [
                            DropdownMenuItem(value: 'Secure', child: Text('Secure')),
                            DropdownMenuItem(value: 'Cooldown', child: Text('Cooldown')),
                            DropdownMenuItem(value: 'Vulnerable', child: Text('Vulnerable')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          ],
                          onChanged: (val) => setModalState(() => status = val ?? 'Secure'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Add Security Bind',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15),
                      ),
                      onPressed: () {
                        if (idNameCtrl.text.trim().isEmpty || currentBindCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in Account Title and Login ID/Email')),
                          );
                          return;
                        }

                        if (isEdit) {
                          bindItem.idName = idNameCtrl.text.trim();
                          bindItem.uid = uidCtrl.text.trim();
                          bindItem.bindType = bindType;
                          bindItem.currentBind = currentBindCtrl.text.trim();
                          bindItem.password = passwordCtrl.text.trim();
                          bindItem.recoveryEmail = recoveryEmailCtrl.text.trim();
                          bindItem.recoveryPhone = recoveryPhoneCtrl.text.trim();
                          bindItem.backupCodes = backupCodesCtrl.text.trim();
                          bindItem.cooldownDate = cooldownDateCtrl.text.trim();
                          bindItem.status = status;
                          storage.updateBind(bindItem);
                        } else {
                          final newBind = BindRecord(
                            id: 'bind-${DateTime.now().millisecondsSinceEpoch}',
                            idRecordId: selectedIdId ?? 'ff-custom',
                            idName: idNameCtrl.text.trim(),
                            uid: uidCtrl.text.trim(),
                            bindType: bindType,
                            currentBind: currentBindCtrl.text.trim(),
                            password: passwordCtrl.text.trim(),
                            recoveryEmail: recoveryEmailCtrl.text.trim(),
                            recoveryPhone: recoveryPhoneCtrl.text.trim(),
                            backupCodes: backupCodesCtrl.text.trim(),
                            cooldownDate: cooldownDateCtrl.text.trim(),
                            status: status,
                          );
                          storage.updateBind(newBind);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BindRecord bind, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Security Bind?'),
        content: Text('Are you sure you want to delete bind details for ${bind.idName}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Delete'),
            onPressed: () {
              storage.deleteBind(bind.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
