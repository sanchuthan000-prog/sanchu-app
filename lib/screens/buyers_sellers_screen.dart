import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BuyersSellersScreen extends StatefulWidget {
  const BuyersSellersScreen({Key? key}) : super(key: key);

  @override
  State<BuyersSellersScreen> createState() => _BuyersSellersScreenState();
}

class _BuyersSellersScreenState extends State<BuyersSellersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Contacts & Partners'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryCyan,
              labelColor: AppTheme.primaryCyan,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Buyers / Customers'),
                Tab(icon: Icon(Icons.storefront), text: 'Sellers / Suppliers'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Buyers Tab
              _buildBuyersTab(storage, currency),
              // Sellers Tab
              _buildSellersTab(storage, currency),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyersTab(StorageService storage, String currency) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: storage.buyers.length,
      itemBuilder: (context, index) {
        final buyer = storage.buyers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryCyan.withOpacity(0.15),
              child: const Icon(Icons.person, color: AppTheme.primaryCyan),
            ),
            title: Text(buyer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Phone: ${buyer.phone} · ${buyer.address}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total: $currency ${buyer.totalPurchases.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (buyer.totalDeo > 0)
                  Text('DEO: $currency ${buyer.totalDeo.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.neonRed, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSellersTab(StorageService storage, String currency) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: storage.sellers.length,
      itemBuilder: (context, index) {
        final seller = storage.sellers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.neonAmber.withOpacity(0.15),
              child: const Icon(Icons.store, color: AppTheme.neonAmber),
            ),
            title: Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Phone: ${seller.phone} · ${seller.notes}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Supplied: ${seller.totalSupplied} IDs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Paid: $currency ${seller.totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.neonGreen, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}
