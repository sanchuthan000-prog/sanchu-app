import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'id_management_screen.dart';
import 'sales_screen.dart';
import 'deo_tracker_screen.dart';
import 'money_tracker_screen.dart';
import 'binds_screen.dart';
import 'buyers_sellers_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  FreeFireId? _preselectedIdForSale;
  final GlobalKey<IdManagementScreenState> _idKey = GlobalKey<IdManagementScreenState>();
  final GlobalKey<SalesScreenState> _salesKey = GlobalKey<SalesScreenState>();

  void _onQuickSell(FreeFireId id) {
    setState(() {
      _preselectedIdForSale = id;
      _currentIndex = 2; // Jump to Sales tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        onNavigateTab: (idx) => setState(() => _currentIndex = idx),
        onOpenAddId: () {
          setState(() => _currentIndex = 1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _idKey.currentState?.showAddEditIdModal(context);
          });
        },
        onOpenRecordSale: () {
          setState(() => _currentIndex = 2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _salesKey.currentState?.showRecordSaleModal(context);
          });
        },
      ),
      IdManagementScreen(key: _idKey, onQuickSell: _onQuickSell),
      SalesScreen(key: _salesKey, preselectedId: _preselectedIdForSale),
      const DeoTrackerScreen(),
      const MoneyTrackerScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppTheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on, color: AppTheme.primaryCyan, size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ALONE ID SALE',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Text(
                    'Free Fire ID & Finance Ledger',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: AppTheme.primaryCyan),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppTheme.neonGreen),
              title: const Text('Free Fire Inventory'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryCyan),
              title: const Text('Sales Management'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions_outlined, color: AppTheme.neonAmber),
              title: const Text('DEO Customer Ledger'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.neonGreen),
              title: const Text('Personal Money Control'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              },
            ),
            const Divider(color: AppTheme.dividerColor),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: AppTheme.neonAmber),
              title: const Text('Account Binds & Security'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BindsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: AppTheme.primaryCyan),
              title: const Text('Buyers & Suppliers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyersSellersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
              title: const Text('Settings & Backup'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 2) _preselectedIdForSale = null;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'IDs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart_outlined),
            activeIcon: Icon(Icons.add_shopping_cart),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'DEO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Money',
          ),
        ],
      ),
    );
  }
}
