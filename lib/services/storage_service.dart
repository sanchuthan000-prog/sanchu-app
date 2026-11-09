import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // In-memory 9 business stores
  List<FreeFireId> ids = [];
  List<Sale> sales = [];
  List<DeoRecord> deoTracker = [];
  List<ExtraPayment> extraPayments = [];
  List<MoneyEntry> moneyEntries = [];
  List<Buyer> buyers = [];
  List<Seller> sellers = [];
  List<BindRecord> binds = [];
  AppSettings settings = AppSettings();

  bool isInitialized = false;
  String syncStatus = 'Offline Ready';
  DateTime? lastSyncTime;

  String get _localFilePath => 'ff_local_snapshot.json';

  Future<void> init() async {
    if (isInitialized) return;
    try {
      final file = File(_localFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        loadFromJson(json);
      } else {
        seedStarterData();
        await saveToLocal();
      }
    } catch (e) {
      debugPrint('Storage init error: $e');
      seedStarterData();
    }
    isInitialized = true;
    notifyListeners();
  }

  void seedStarterData() {
    ids = [
      FreeFireId(
        id: 'ff-101',
        name: 'Grandmaster Lvl 74 · Cobra MP40 Max · Evo Bundle',
        uid: '1092837461',
        level: 74,
        price: 32000.0,
        costPrice: 22000.0,
        status: 'Available',
        likes: '14200',
        badges: ['Verified', 'Grandmaster', 'Evo Max'],
        description: 'Elite pass from S2, 7 Max Evo Guns, 2FA ready, instant transfer.',
        images: ['https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800'],
        currentGmail: 'ffalone.store77@gmail.com',
        bindType: 'Gmail',
        bindStatus: 'Google / 2FA Ready',
        bindCooldown: 'Clean (0 days)',
        sellerName: 'Vikram Supplier',
        sellerPhone: '+919876543210',
        paidToSeller: 22000.0,
        pendingToSeller: 0.0,
      ),
      FreeFireId(
        id: 'ff-102',
        name: 'Lvl 68 · Sakura S1 Season 1 Hoodie · Old Pass',
        uid: '2381947561',
        level: 68,
        price: 26500.0,
        costPrice: 18000.0,
        status: 'Sold',
        likes: '9850',
        badges: ['Sakura S1', 'Old Season'],
        description: 'Rare OG collector account with original Season 1 pass badge.',
        images: ['https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=800'],
        currentGmail: 'buyer.kavin@gmail.com',
        bindType: 'Gmail',
        bindStatus: 'Transferred',
        bindCooldown: 'Transferred',
        sellerName: 'Alone Gaming Supplier',
        sellerPhone: '+919876500111',
        paidToSeller: 15000.0,
        pendingToSeller: 3000.0,
      ),
      FreeFireId(
        id: 'ff-103',
        name: 'Lvl 71 · Blue Dino · Poker MP40 · Arctic Blue',
        uid: '5647382910',
        level: 71,
        price: 15500.0,
        costPrice: 10500.0,
        status: 'Available',
        likes: '8400',
        badges: ['Blue Dino', 'Poker MP40'],
        description: 'Clean Gmail binding with recovery codes ready for handover.',
        images: ['https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800'],
        currentGmail: 'ffalone.stock2@gmail.com',
        bindType: 'Gmail',
        bindStatus: 'Google / 2FA Ready',
        bindCooldown: 'Clean',
        sellerName: 'Vikram Supplier',
        sellerPhone: '+919876543210',
        paidToSeller: 10500.0,
        pendingToSeller: 0.0,
      ),
    ];

    sales = [
      Sale(
        id: 'sale-101',
        idRecordId: 'ff-102',
        idName: 'Lvl 68 · Sakura S1 Season 1 Hoodie',
        uid: '2381947561',
        buyerName: 'Kavin Kumar',
        buyerPhone: '+919876500111',
        salePrice: 26500.0,
        costPrice: 18000.0,
        profit: 8500.0,
        paidAmount: 20000.0,
        remainingDeo: 6500.0,
        status: 'Partial',
        paymentMethod: 'GPay',
        bankName: 'Commercial Bank',
        txnId: 'TXN-9988231',
        dueDate: '2026-11-15',
        overdueFinePerDay: 50.0,
        date: '2026-11-04',
        notes: 'Downpayment 20k, remaining 6.5k due on next Sunday',
      ),
    ];

    deoTracker = [
      DeoRecord(
        id: 'deo-101',
        saleId: 'sale-101',
        idName: 'Lvl 68 · Sakura S1 Season 1 Hoodie',
        customerName: 'Kavin Kumar',
        customerPhone: '+919876500111',
        totalAmount: 26500.0,
        paidAmount: 20000.0,
        remainingDeo: 6500.0,
        status: 'Active',
        dueDate: '2026-11-15',
        finePerDay: 50.0,
        lastPaymentDate: '2026-11-04',
        payments: [
          DeoPayment(
            id: 'pay-1',
            amount: 20000.0,
            date: '2026-11-04',
            paymentMethod: 'GPay',
            notes: 'Initial downpayment',
            receiptNumber: 'RCP-8812',
          ),
        ],
      ),
    ];

    extraPayments = [
      ExtraPayment(
        id: 'ex-1',
        deoId: 'deo-101',
        buyerName: 'Kavin Kumar',
        title: 'Top-up 520 Diamonds for Name Change',
        amount: 400.0,
        date: '2026-11-05',
      ),
    ];

    moneyEntries = [
      MoneyEntry(
        id: 'sale-profit:sale-101',
        type: 'income',
        title: 'ID sale profit · Lvl 68 · Sakura S1',
        category: 'ID Sale Profit',
        amount: 8500.0,
        date: '2026-11-04',
        time: '16:30',
        sourceSaleId: 'sale-101',
        notes: 'Automated deal profit (Sale 26.5k - Cost 18k)',
      ),
      MoneyEntry(
        id: 'm-1',
        type: 'expense',
        title: 'Shop Wi-Fi & Internet Bill',
        category: 'Utilities',
        amount: 1200.0,
        date: '2026-11-02',
        time: '11:00',
        notes: 'Monthly broadband for ID transfers',
      ),
    ];

    buyers = [
      Buyer(
        id: 'b-1',
        name: 'Kavin Kumar',
        phone: '+919876500111',
        whatsapp: '+919876500111',
        address: 'Chennai, TN',
        totalPurchases: 26500.0,
        totalDeo: 6500.0,
        notes: 'Regular client. Likes Evo guns and Sakura items.',
      ),
    ];

    sellers = [
      Seller(
        id: 's-1',
        name: 'Vikram Supplier',
        phone: '+919876543210',
        bankName: 'State Bank of India',
        upiId: 'vikram.gamer@oksbi',
        accountNo: '30981248561',
        ifsc: 'SBIN0001234',
        totalSupplied: 5,
        totalSourcingCost: 95000.0,
        totalPaid: 92000.0,
        pendingBalance: 3000.0,
        notes: 'Trusted ID seller. All Gmail bindings clean.',
      ),
    ];

    binds = [
      BindRecord(
        id: 'bind-101',
        idRecordId: 'ff-101',
        idName: 'Grandmaster Lvl 74 · Cobra MP40 Max',
        uid: '1092837461',
        bindType: 'Gmail',
        currentBind: 'ffalone.store77@gmail.com',
        recoveryEmail: 'alone.recovery@gmail.com',
        recoveryPhone: '+919876543210',
        cooldownDate: '2026-11-12',
        status: 'Secure',
      ),
    ];
  }

  // --- Executive Dashboard Metrics ---
  int get stockAccountsCount => ids.where((e) => e.status.toLowerCase() == 'available').length;
  int get soldAccountsCount => ids.where((e) => e.status.toLowerCase() == 'sold').length;
  double get totalSalesRevenue => sales.fold(0.0, (acc, item) => acc + item.salePrice);
  double get totalNetProfit => sales.fold(0.0, (acc, item) => acc + item.profit);
  double get pendingCustomerDeo => deoTracker.where((d) => d.status != 'Settled').fold(0.0, (acc, item) => acc + item.remainingDeo);
  double get pendingSupplierDues => sellers.fold(0.0, (acc, item) => acc + item.pendingBalance);

  double get totalPersonalIncome => moneyEntries.where((m) => m.type == 'income').fold(0.0, (acc, item) => acc + item.amount);
  double get totalPersonalExpense => moneyEntries.where((m) => m.type == 'expense').fold(0.0, (acc, item) => acc + item.amount);
  double get netPersonalBalance => totalPersonalIncome - totalPersonalExpense;

  // Outstanding Grand Total for a specific DEO customer
  double calculateGrandTotalDue(String deoId) {
    final deo = deoTracker.firstWhere((d) => d.id == deoId, orElse: () => DeoRecord(id: '', saleId: '', idName: '', customerName: '', totalAmount: 0, paidAmount: 0));
    final extras = extraPayments.where((e) => e.deoId == deoId).fold(0.0, (sum, e) => sum + e.amount);
    return deo.remainingDeo + extras + deo.overdueFine;
  }

  // --- CRUD: Free Fire IDs ---
  Future<void> addId(FreeFireId idItem) async {
    ids.insert(0, idItem);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> updateId(FreeFireId updated) async {
    final index = ids.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      ids[index] = updated;
      await saveToLocal();
      notifyListeners();
    }
  }

  Future<void> deleteId(String id) async {
    ids.removeWhere((e) => e.id == id);
    await saveToLocal();
    notifyListeners();
  }

  // --- CRUD: Sales ---
  Future<bool> createSale(Sale sale, {bool linkToMoneyEntries = true}) async {
    final existingSale = sales.any((s) => s.idRecordId == sale.idRecordId);
    if (existingSale) return false;

    sales.insert(0, sale);

    // Update ID status
    final idIndex = ids.indexWhere((item) => item.id == sale.idRecordId);
    if (idIndex != -1) {
      ids[idIndex].status = 'Sold';
    }

    // Update Buyer CRM stats
    final buyerIndex = buyers.indexWhere((b) => b.name.toLowerCase() == sale.buyerName.toLowerCase());
    if (buyerIndex != -1) {
      buyers[buyerIndex].totalPurchases += sale.salePrice;
      buyers[buyerIndex].totalDeo += sale.remainingDeo;
    } else {
      buyers.add(Buyer(
        id: 'b-${DateTime.now().millisecondsSinceEpoch}',
        name: sale.buyerName,
        phone: sale.buyerPhone,
        totalPurchases: sale.salePrice,
        totalDeo: sale.remainingDeo,
      ));
    }

    // Create DEO Tracker entry if balance due exists
    if (sale.remainingDeo > 0) {
      final deo = DeoRecord(
        id: 'deo-${DateTime.now().millisecondsSinceEpoch}',
        saleId: sale.id,
        idName: sale.idName,
        customerName: sale.buyerName,
        customerPhone: sale.buyerPhone,
        totalAmount: sale.salePrice,
        paidAmount: sale.paidAmount,
        remainingDeo: sale.remainingDeo,
        status: 'Active',
        dueDate: sale.dueDate.isNotEmpty ? sale.dueDate : DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
        finePerDay: sale.overdueFinePerDay,
        lastPaymentDate: sale.date,
        payments: [
          DeoPayment(
            id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
            amount: sale.paidAmount,
            date: sale.date,
            paymentMethod: sale.paymentMethod,
            notes: 'Initial downpayment on deal',
          ),
        ],
      );
      deoTracker.insert(0, deo);
    }

    // Profit-only sync with confirmation
    if (linkToMoneyEntries) {
      upsertSaleProfit(sale);
    }

    await saveToLocal();
    notifyListeners();
    return true;
  }

  void upsertSaleProfit(Sale sale) {
    final deterministicId = 'sale-profit:${sale.id}';
    final existingIndex = moneyEntries.indexWhere((m) => m.id == deterministicId || m.sourceSaleId == sale.id);

    final profit = sale.profit;
    final entry = MoneyEntry(
      id: deterministicId,
      type: profit >= 0 ? 'income' : 'expense',
      title: profit >= 0 ? 'ID sale profit · ${sale.idName}' : 'ID sale loss · ${sale.idName}',
      category: 'ID Sale Profit',
      amount: profit.abs(),
      date: sale.date,
      time: '12:00',
      sourceSaleId: sale.id,
      notes: 'Deal profit (Sale ${sale.salePrice} - Cost ${sale.costPrice})',
    );

    if (existingIndex != -1) {
      moneyEntries[existingIndex] = entry;
    } else {
      moneyEntries.insert(0, entry);
    }
  }

  Future<void> deleteSale(String saleId, {bool removeLinkedProfit = true}) async {
    sales.removeWhere((s) => s.id == saleId);
    if (removeLinkedProfit) {
      moneyEntries.removeWhere((m) => m.id == 'sale-profit:$saleId' || m.sourceSaleId == saleId);
    }
    await saveToLocal();
    notifyListeners();
  }

  // --- CRUD: DEO & Payments ---
  Future<void> addDeoPayment(String deoId, DeoPayment payment) async {
    final index = deoTracker.indexWhere((d) => d.id == deoId);
    if (index != -1) {
      final deo = deoTracker[index];
      deo.payments.insert(0, payment);
      deo.paidAmount += payment.amount;
      deo.remainingDeo = (deo.totalAmount - deo.paidAmount).clamp(0.0, double.infinity);
      deo.lastPaymentDate = payment.date;
      if (deo.remainingDeo <= 0) {
        deo.status = 'Settled';
      }
      await saveToLocal();
      notifyListeners();
    }
  }

  // --- CRUD: Extra Payments ---
  Future<void> addExtraPayment(ExtraPayment extra) async {
    extraPayments.insert(0, extra);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> deleteExtraPayment(String id) async {
    extraPayments.removeWhere((e) => e.id == id);
    await saveToLocal();
    notifyListeners();
  }

  // --- CRUD: Money Entries ---
  Future<void> addMoneyEntry(MoneyEntry entry) async {
    moneyEntries.insert(0, entry);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> updateMoneyEntry(MoneyEntry updated) async {
    final index = moneyEntries.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      moneyEntries[index] = updated;
      await saveToLocal();
      notifyListeners();
    }
  }

  Future<void> deleteMoneyEntry(String id) async {
    moneyEntries.removeWhere((m) => m.id == id);
    await saveToLocal();
    notifyListeners();
  }

  // --- CRUD: Contacts & Suppliers ---
  Future<void> addBuyer(Buyer buyer) async {
    buyers.insert(0, buyer);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> updateBuyer(Buyer updated) async {
    final index = buyers.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      buyers[index] = updated;
      await saveToLocal();
      notifyListeners();
    }
  }

  Future<void> deleteBuyer(String id) async {
    buyers.removeWhere((b) => b.id == id);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> addSeller(Seller seller) async {
    sellers.insert(0, seller);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> updateSeller(Seller updated) async {
    final index = sellers.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      sellers[index] = updated;
      await saveToLocal();
      notifyListeners();
    }
  }

  Future<void> deleteSeller(String id) async {
    sellers.removeWhere((s) => s.id == id);
    await saveToLocal();
    notifyListeners();
  }

  Future<void> recordSupplierPayout(String sellerId, double payoutAmount, {String notes = ''}) async {
    final index = sellers.indexWhere((s) => s.id == sellerId);
    if (index != -1) {
      final s = sellers[index];
      s.totalPaid += payoutAmount;
      s.pendingBalance = (s.totalSourcingCost - s.totalPaid).clamp(0.0, double.infinity);

      // Record in Personal Money as Business Expense
      moneyEntries.insert(0, MoneyEntry(
        id: 'payout-${DateTime.now().millisecondsSinceEpoch}',
        type: 'expense',
        title: 'Supplier Payout · ${s.name}',
        category: 'Business',
        amount: payoutAmount,
        date: DateTime.now().toIso8601String().substring(0, 10),
        time: '12:00',
        notes: notes.isNotEmpty ? notes : 'Paid towards supplier balance',
      ));

      await saveToLocal();
      notifyListeners();
    }
  }

  // --- CRUD: Binds ---
  Future<void> updateBind(BindRecord updated) async {
    final index = binds.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      binds[index] = updated;
    } else {
      binds.insert(0, updated);
    }
    await saveToLocal();
    notifyListeners();
  }

  Future<void> deleteBind(String id) async {
    binds.removeWhere((b) => b.id == id);
    await saveToLocal();
    notifyListeners();
  }

  // --- Snapshot Backup & Restore ---
  Map<String, dynamic> exportFullSnapshot() {
    return {
      'id': 'main',
      'updated_at': DateTime.now().toIso8601String(),
      'data': {
        'ids': ids.map((e) => e.toJson()).toList(),
        'sales': sales.map((e) => e.toJson()).toList(),
        'deoTracker': deoTracker.map((e) => e.toJson()).toList(),
        'extraPayments': extraPayments.map((e) => e.toJson()).toList(),
        'moneyEntries': moneyEntries.map((e) => e.toJson()).toList(),
        'buyers': buyers.map((e) => e.toJson()).toList(),
        'sellers': sellers.map((e) => e.toJson()).toList(),
        'binds': binds.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
      }
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    if (data['ids'] is List) ids = (data['ids'] as List).map((e) => FreeFireId.fromJson(e as Map<String, dynamic>)).toList();
    if (data['sales'] is List) sales = (data['sales'] as List).map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
    if (data['deoTracker'] is List) deoTracker = (data['deoTracker'] as List).map((e) => DeoRecord.fromJson(e as Map<String, dynamic>)).toList();
    if (data['extraPayments'] is List) extraPayments = (data['extraPayments'] as List).map((e) => ExtraPayment.fromJson(e as Map<String, dynamic>)).toList();
    if (data['moneyEntries'] is List) moneyEntries = (data['moneyEntries'] as List).map((e) => MoneyEntry.fromJson(e as Map<String, dynamic>)).toList();
    if (data['buyers'] is List) buyers = (data['buyers'] as List).map((e) => Buyer.fromJson(e as Map<String, dynamic>)).toList();
    if (data['sellers'] is List) sellers = (data['sellers'] as List).map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
    if (data['binds'] is List) binds = (data['binds'] as List).map((e) => BindRecord.fromJson(e as Map<String, dynamic>)).toList();
    if (data['settings'] is Map<String, dynamic>) settings = AppSettings.fromJson(data['settings']);
    notifyListeners();
  }

  Future<void> saveToLocal() async {
    try {
      final snapshot = exportFullSnapshot();
      final file = File(_localFilePath);
      await file.writeAsString(jsonEncode(snapshot));
      lastSyncTime = DateTime.now();
      syncStatus = 'Saved';
    } catch (e) {
      debugPrint('Error saving local snapshot: $e');
    }
  }
}
