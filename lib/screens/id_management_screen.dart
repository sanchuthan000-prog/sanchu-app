import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs_and_widgets.dart';

class IdManagementScreen extends StatefulWidget {
  final Function(FreeFireId)? onQuickSell;

  const IdManagementScreen({Key? key, this.onQuickSell}) : super(key: key);

  @override
  State<IdManagementScreen> createState() => IdManagementScreenState();
}

class IdManagementScreenState extends State<IdManagementScreen> {
  String searchQuery = '';
  String filterStatus = 'All'; // 'All' | 'Available' | 'Reserved' | 'Sold'
  bool isGridView = false; // Grid view vs List/Table view switcher

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        final filteredIds = storage.ids.where((item) {
          final query = searchQuery.toLowerCase();
          final matchesSearch = item.name.toLowerCase().contains(query) ||
              item.uid.toLowerCase().contains(query) ||
              item.sellerName.toLowerCase().contains(query) ||
              item.badges.any((b) => b.toLowerCase().contains(query));
          final matchesFilter = filterStatus == 'All' || item.status.toLowerCase() == filterStatus.toLowerCase();
          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Free Fire ID Inventory'),
            actions: [
              IconButton(
                icon: Icon(isGridView ? Icons.view_list : Icons.grid_view, color: AppTheme.neonCyan),
                tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
                onPressed: () => setState(() => isGridView = !isGridView),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.neonCyan),
                onPressed: () => showAddEditIdModal(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                        hintText: 'Search by Title, Game UID, Seller, Badges...',
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Available', 'Reserved', 'Sold'].map((status) {
                          final isSelected = filterStatus == status;
                          Color color = AppTheme.primaryBlue;
                          if (status == 'Available') color = AppTheme.emeraldGreen;
                          if (status == 'Reserved') color = AppTheme.amberWarning;
                          if (status == 'Sold') color = AppTheme.roseRed;

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) => setState(() => filterStatus = status),
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
                  ],
                ),
              ),

              // Inventory Content: Grid View or List View
              Expanded(
                child: filteredIds.isEmpty
                    ? const Center(child: Text('No accounts found matching filter', style: TextStyle(color: AppTheme.textMuted)))
                    : isGridView
                        ? _buildGridView(context, filteredIds, storage, currency)
                        : _buildListView(context, filteredIds, storage, currency),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('+ ADD ACCOUNT'),
            onPressed: () => showAddEditIdModal(context),
          ),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<FreeFireId> ids, StorageService storage, String currency) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final item = ids[index];
        return _buildIdCard(context, item, storage, currency);
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<FreeFireId> ids, StorageService storage, String currency) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final item = ids[index];
        return _buildIdCard(context, item, storage, currency, isCompact: true);
      },
    );
  }

  Widget _buildIdCard(BuildContext context, FreeFireId item, StorageService storage, String currency, {bool isCompact = false}) {
    final isAvailable = item.status.toLowerCase() == 'available';
    final isReserved = item.status.toLowerCase() == 'reserved';
    final expectedProfit = item.price - item.costPrice;

    Color statusColor = isAvailable ? AppTheme.emeraldGreen : (isReserved ? AppTheme.amberWarning : AppTheme.roseRed);

    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 0 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Cover Thumbnail with "+X photos" Badge
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (item.images.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => ImagePreviewDialog(images: item.images),
                    );
                  }
                },
                child: Container(
                  height: isCompact ? 110 : 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    image: item.images.isNotEmpty && item.images.first.startsWith('http')
                        ? DecorationImage(image: NetworkImage(item.images.first), fit: BoxFit.cover)
                        : null,
                  ),
                  child: item.images.isEmpty || !item.images.first.startsWith('http')
                      ? const Center(child: Icon(Icons.sports_esports, size: 40, color: AppTheme.primaryBlue))
                      : null,
                ),
              ),

              // Level badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                  child: Text('Lv. ${item.level}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              // Status badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),

              // Multi-photo count badge
              if (item.images.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                    child: Text('+${item.images.length} photos', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // UID with 1-tap Copy
                Row(
                  children: [
                    Text('UID: ${item.uid}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied UID: ${item.uid}')),
                        );
                      },
                      child: const Icon(Icons.copy, size: 14, color: AppTheme.neonCyan),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Key Badges
                if (item.badges.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: item.badges.take(2).map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(b, style: const TextStyle(color: AppTheme.neonCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Sourcing & Supplier info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 12, color: AppTheme.neonAmber),
                          const SizedBox(width: 4),
                          Text('Supplier: ${item.sellerName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        ],
                      ),
                      Text(item.currentGmail.isNotEmpty ? item.currentGmail : 'No Bind', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                ),

                // Pricing Row: Cost Price | Customer Price | Profit
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cost / Buy Price', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                          Text('$currency ${item.costPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.roseRed, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Customer Price', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                          Text('$currency ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Profit', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                          Text('+Rs. ${expectedProfit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!isCompact) ...[
                  const Divider(color: AppTheme.dividerColor, height: 18),
                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isAvailable && widget.onQuickSell != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                          label: const Text('Record Sale'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => widget.onQuickSell!(item),
                        ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.neonCyan, size: 18),
                        onPressed: () => showAddEditIdModal(context, idItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.roseRed, size: 18),
                        onPressed: () => _confirmDelete(context, item),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showAddEditIdModal(BuildContext context, {FreeFireId? idItem}) {
    final isEdit = idItem != null;
    final nameCtrl = TextEditingController(text: idItem?.name ?? '');
    final uidCtrl = TextEditingController(text: idItem?.uid ?? '');
    final levelCtrl = TextEditingController(text: idItem != null ? '${idItem.level}' : '65');
    final priceCtrl = TextEditingController(text: idItem != null ? '${idItem.price.toStringAsFixed(0)}' : '');
    final costCtrl = TextEditingController(text: idItem != null ? '${idItem.costPrice.toStringAsFixed(0)}' : '');
    final gmailCtrl = TextEditingController(text: idItem?.currentGmail ?? '');
    final badgesCtrl = TextEditingController(text: idItem?.badges.join(', ') ?? '7 Evo Max, Sakura S1');
    final descCtrl = TextEditingController(text: idItem?.description ?? '');
    final notesCtrl = TextEditingController(text: idItem?.notes ?? '');

    // Seller fields
    final storage = StorageService();
    String selectedSeller = idItem?.sellerName ?? (storage.sellers.isNotEmpty ? storage.sellers.first.name : 'Direct Sourcing');
    bool isNewSeller = false;
    final newSellerNameCtrl = TextEditingController();
    final newSellerPhoneCtrl = TextEditingController();
    final newSellerUpiCtrl = TextEditingController();

    // Photo URLs list
    List<String> uploadedImages = List.from(idItem?.images ?? []);
    final urlInputCtrl = TextEditingController();
    String status = idItem?.status ?? 'Available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final costVal = double.tryParse(costCtrl.text) ?? 0.0;
          final paidVal = costVal; // default paid
          final pendingVal = 0.0;

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
                        isEdit ? 'Edit Free Fire ID' : 'Add New Free Fire ID',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Title / Highlights *')),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(child: TextField(controller: uidCtrl, decoration: const InputDecoration(labelText: 'Free Fire UID *'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: levelCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Level'))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Buying / Cost Price (Rs.) *'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Customer Selling Price (Rs.) *'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Expected Margin / Profit:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          'Rs. ${((double.tryParse(priceCtrl.text) ?? 0.0) - (double.tryParse(costCtrl.text) ?? 0.0)) >= 0 ? "+" : ""}${((double.tryParse(priceCtrl.text) ?? 0.0) - (double.tryParse(costCtrl.text) ?? 0.0)).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: ((double.tryParse(priceCtrl.text) ?? 0.0) - (double.tryParse(costCtrl.text) ?? 0.0)) >= 0 ? AppTheme.emeraldGreen : AppTheme.roseRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SOURCING / SELLER SECTION
                  const Text('SOURCING & SUPPLIER DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: isNewSeller ? '+ Add New Seller...' : (storage.sellers.any((s) => s.name == selectedSeller) ? selectedSeller : '+ Add New Seller...'),
                    dropdownColor: AppTheme.surfaceLight,
                    items: [
                      ...storage.sellers.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                      const DropdownMenuItem(value: '+ Add New Seller...', child: Text('+ Add New Seller...', style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        if (val == '+ Add New Seller...') {
                          isNewSeller = true;
                        } else {
                          isNewSeller = false;
                          selectedSeller = val ?? 'Direct Sourcing';
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Seller / Supplier'),
                  ),

                  // Inline New Seller Fields
                  if (isNewSeller) ...[
                    const SizedBox(height: 8),
                    TextField(controller: newSellerNameCtrl, decoration: const InputDecoration(labelText: 'New Seller Name *')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: newSellerPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone / WhatsApp'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: newSellerUpiCtrl, decoration: const InputDecoration(labelText: 'UPI ID / Bank IFSC'))),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paid to Seller: Rs. ${paidVal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 12)),
                      Text('Pending to Seller: Rs. ${pendingVal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bind & Badges
                  TextField(controller: gmailCtrl, decoration: const InputDecoration(labelText: 'Current Linked Gmail / Bind')),
                  const SizedBox(height: 8),
                  TextField(controller: badgesCtrl, decoration: const InputDecoration(labelText: 'Key Badges (comma-separated)')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Vault & Skins Description')),
                  const SizedBox(height: 12),

                  // PHOTO UPLOAD & URL MANAGER
                  const Text('PHOTOS & SCREENSHOTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlInputCtrl,
                          decoration: const InputDecoration(hintText: 'Paste Image URL (https://...)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: AppTheme.neonCyan),
                        child: const Text('+ Add URL'),
                        onPressed: () {
                          if (urlInputCtrl.text.isNotEmpty) {
                            setModalState(() {
                              uploadedImages.add(urlInputCtrl.text.trim());
                              urlInputCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Tap to add sample screenshot
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                    label: const Text('Add Demo Free Fire Screenshot'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonCyan,
                      side: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    onPressed: () {
                      setModalState(() {
                        uploadedImages.add('https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800');
                      });
                    },
                  ),

                  // Thumbnails list with delete [X]
                  if (uploadedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: uploadedImages.length,
                        itemBuilder: (ctx, i) {
                          return Stack(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryBlue),
                                  image: uploadedImages[i].startsWith('http')
                                      ? DecorationImage(image: NetworkImage(uploadedImages[i]), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: !uploadedImages[i].startsWith('http')
                                    ? const Center(child: Icon(Icons.image, size: 24, color: AppTheme.primaryBlue))
                                    : null,
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: InkWell(
                                  onTap: () => setModalState(() => uploadedImages.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Internal Notes (recovery codes, etc.)')),
                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text(isEdit ? 'UPDATE ACCOUNT' : 'SAVE FREE FIRE ID'),
                      onPressed: () {
                        if (nameCtrl.text.isEmpty || uidCtrl.text.isEmpty) return;

                        // Create seller if new
                        String finalSeller = selectedSeller;
                        if (isNewSeller && newSellerNameCtrl.text.isNotEmpty) {
                          finalSeller = newSellerNameCtrl.text;
                          storage.addSeller(Seller(
                            id: 's-${DateTime.now().millisecondsSinceEpoch}',
                            name: finalSeller,
                            phone: newSellerPhoneCtrl.text,
                            upiId: newSellerUpiCtrl.text,
                            totalSupplied: 1,
                            totalSourcingCost: double.tryParse(costCtrl.text) ?? 0.0,
                            totalPaid: double.tryParse(costCtrl.text) ?? 0.0,
                          ));
                        }

                        final badgesList = badgesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                        if (isEdit) {
                          idItem.name = nameCtrl.text;
                          idItem.uid = uidCtrl.text;
                          idItem.level = int.tryParse(levelCtrl.text) ?? 1;
                          idItem.price = double.tryParse(priceCtrl.text) ?? 0.0;
                          idItem.costPrice = double.tryParse(costCtrl.text) ?? 0.0;
                          idItem.currentGmail = gmailCtrl.text;
                          idItem.badges = badgesList;
                          idItem.description = descCtrl.text;
                          idItem.images = uploadedImages;
                          idItem.sellerName = finalSeller;
                          idItem.notes = notesCtrl.text;
                          storage.updateId(idItem);
                        } else {
                          storage.addId(FreeFireId(
                            id: 'ff-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text,
                            uid: uidCtrl.text,
                            level: int.tryParse(levelCtrl.text) ?? 1,
                            price: double.tryParse(priceCtrl.text) ?? 0.0,
                            costPrice: double.tryParse(costCtrl.text) ?? 0.0,
                            currentGmail: gmailCtrl.text,
                            badges: badgesList,
                            description: descCtrl.text,
                            images: uploadedImages,
                            sellerName: finalSeller,
                            notes: notesCtrl.text,
                          ));
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

  void _confirmDelete(BuildContext context, FreeFireId item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to remove ${item.name} (${item.uid})?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Delete'),
            onPressed: () {
              StorageService().deleteId(item.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
