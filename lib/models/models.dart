// Clean models

/// Free Fire Account Inventory Model
class FreeFireId {
  String id;
  String name;
  String uid;
  int level;
  double price;
  double costPrice;
  String status; // 'Available' | 'Reserved' | 'Sold'
  String likes;
  List<String> badges;
  String description;
  List<String> images;
  String currentGmail;
  String bindStatus;
  String bindCooldown;
  String sellerName;
  String sellerPhone;
  String createdAt;
  String notes;

  FreeFireId({
    required this.id,
    required this.name,
    required this.uid,
    this.level = 1,
    this.price = 0.0,
    this.costPrice = 0.0,
    this.status = 'Available',
    this.likes = '0',
    List<String>? badges,
    this.description = '',
    List<String>? images,
    this.currentGmail = '',
    this.bindStatus = 'Google / 2FA Ready',
    this.bindCooldown = 'Clean',
    this.sellerName = '',
    this.sellerPhone = '',
    String? createdAt,
    this.notes = '',
  })  : badges = badges ?? [],
        images = images ?? [],
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'uid': uid,
        'level': level,
        'price': price,
        'costPrice': costPrice,
        'status': status,
        'likes': likes,
        'badges': badges,
        'description': description,
        'images': images,
        'currentGmail': currentGmail,
        'bindStatus': bindStatus,
        'bindCooldown': bindCooldown,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'createdAt': createdAt,
        'notes': notes,
      };

  factory FreeFireId.fromJson(Map<String, dynamic> json) => FreeFireId(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        uid: json['uid']?.toString() ?? '',
        level: (json['level'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? 'Available',
        likes: json['likes']?.toString() ?? '0',
        badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
        description: json['description']?.toString() ?? '',
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        currentGmail: json['currentGmail']?.toString() ?? '',
        bindStatus: json['bindStatus']?.toString() ?? 'Google / 2FA Ready',
        bindCooldown: json['bindCooldown']?.toString() ?? 'Clean',
        sellerName: json['sellerName']?.toString() ?? '',
        sellerPhone: json['sellerPhone']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        notes: json['notes']?.toString() ?? '',
      );
}

/// Sale Transaction Model
class Sale {
  String id;
  String idRecordId;
  String idName;
  String uid;
  String buyerName;
  String buyerPhone;
  double salePrice;
  double costPrice;
  double profit;
  double paidAmount;
  double remainingDeo;
  String status; // 'Full Paid' | 'Partial'
  String paymentMethod;
  String date;
  String notes;

  Sale({
    required this.id,
    required this.idRecordId,
    required this.idName,
    required this.uid,
    required this.buyerName,
    this.buyerPhone = '',
    required this.salePrice,
    required this.costPrice,
    double? profit,
    required this.paidAmount,
    double? remainingDeo,
    this.status = 'Full Paid',
    this.paymentMethod = 'GPay / UPI',
    String? date,
    this.notes = '',
  })  : profit = profit ?? (salePrice - costPrice),
        remainingDeo = remainingDeo ?? (salePrice - paidAmount),
        date = date ?? DateTime.now().toIso8601String().substring(0, 10);

  Map<String, dynamic> toJson() => {
        'id': id,
        'idRecordId': idRecordId,
        'idName': idName,
        'uid': uid,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'salePrice': salePrice,
        'costPrice': costPrice,
        'profit': profit,
        'paidAmount': paidAmount,
        'remainingDeo': remainingDeo,
        'status': status,
        'paymentMethod': paymentMethod,
        'date': date,
        'notes': notes,
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id']?.toString() ?? '',
        idRecordId: json['idRecordId']?.toString() ?? '',
        idName: json['idName']?.toString() ?? '',
        uid: json['uid']?.toString() ?? '',
        buyerName: json['buyerName']?.toString() ?? '',
        buyerPhone: json['buyerPhone']?.toString() ?? '',
        salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
        costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
        profit: (json['profit'] as num?)?.toDouble(),
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
        remainingDeo: (json['remainingDeo'] as num?)?.toDouble(),
        status: json['status']?.toString() ?? 'Full Paid',
        paymentMethod: json['paymentMethod']?.toString() ?? 'GPay / UPI',
        date: json['date']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
}

/// DEO Payment History Entry
class DeoPayment {
  String id;
  double amount;
  String date;
  String paymentMethod;
  String notes;
  String receiptNumber;

  DeoPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.paymentMethod = 'GPay / UPI',
    this.notes = '',
    this.receiptNumber = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'receiptNumber': receiptNumber,
      };

  factory DeoPayment.fromJson(Map<String, dynamic> json) => DeoPayment(
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date']?.toString() ?? '',
        paymentMethod: json['paymentMethod']?.toString() ?? 'GPay / UPI',
        notes: json['notes']?.toString() ?? '',
        receiptNumber: json['receiptNumber']?.toString() ?? '',
      );
}

/// Customer DEO Ledger Model
class DeoRecord {
  String id;
  String saleId;
  String idName;
  String customerName;
  String customerPhone;
  double totalAmount;
  double paidAmount;
  double remainingDeo;
  String status; // 'Active' | 'Settled' | 'Overdue'
  String dueDate;
  String lastPaymentDate;
  List<DeoPayment> payments;

  DeoRecord({
    required this.id,
    required this.saleId,
    required this.idName,
    required this.customerName,
    this.customerPhone = '',
    required this.totalAmount,
    required this.paidAmount,
    double? remainingDeo,
    this.status = 'Active',
    this.dueDate = '',
    this.lastPaymentDate = '',
    List<DeoPayment>? payments,
  })  : remainingDeo = remainingDeo ?? (totalAmount - paidAmount),
        payments = payments ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'saleId': saleId,
        'idName': idName,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingDeo': remainingDeo,
        'status': status,
        'dueDate': dueDate,
        'lastPaymentDate': lastPaymentDate,
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  factory DeoRecord.fromJson(Map<String, dynamic> json) => DeoRecord(
        id: json['id']?.toString() ?? '',
        saleId: json['saleId']?.toString() ?? '',
        idName: json['idName']?.toString() ?? '',
        customerName: json['customerName']?.toString() ?? '',
        customerPhone: json['customerPhone']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
        remainingDeo: (json['remainingDeo'] as num?)?.toDouble(),
        status: json['status']?.toString() ?? 'Active',
        dueDate: json['dueDate']?.toString() ?? '',
        lastPaymentDate: json['lastPaymentDate']?.toString() ?? '',
        payments: (json['payments'] as List?)
                ?.map((e) => DeoPayment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Extra Payment (Additional Dues Linked to DEO)
class ExtraPayment {
  String id;
  String deoId;
  String buyerName;
  String title;
  double amount;
  String date;

  ExtraPayment({
    required this.id,
    required this.deoId,
    required this.buyerName,
    required this.title,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deoId': deoId,
        'buyerName': buyerName,
        'title': title,
        'amount': amount,
        'date': date,
      };

  factory ExtraPayment.fromJson(Map<String, dynamic> json) => ExtraPayment(
        id: json['id']?.toString() ?? '',
        deoId: json['deoId']?.toString() ?? '',
        buyerName: json['buyerName']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date']?.toString() ?? '',
      );
}

/// Personal Money & Profit Control Model
class MoneyEntry {
  String id;
  String type; // 'income' | 'expense'
  String title;
  String category;
  double amount;
  String date;
  String time;
  String notes;
  String? sourceSaleId;
  String createdAt;
  String updatedAt;

  MoneyEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.time = '12:00',
    this.notes = '',
    this.sourceSaleId,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date,
        'time': time,
        'notes': notes,
        'sourceSaleId': sourceSaleId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'income',
        title: json['title']?.toString() ?? '',
        category: json['category']?.toString() ?? 'General',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '12:00',
        notes: json['notes']?.toString() ?? '',
        sourceSaleId: json['sourceSaleId']?.toString(),
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
      );
}

/// Buyer Customer Model
class Buyer {
  String id;
  String name;
  String phone;
  String address;
  double totalPurchases;
  double totalDeo;
  String notes;

  Buyer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.totalPurchases = 0.0,
    this.totalDeo = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'totalPurchases': totalPurchases,
        'totalDeo': totalDeo,
        'notes': notes,
      };

  factory Buyer.fromJson(Map<String, dynamic> json) => Buyer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0.0,
        totalDeo: (json['totalDeo'] as num?)?.toDouble() ?? 0.0,
        notes: json['notes']?.toString() ?? '',
      );
}

/// Seller Supplier Model
class Seller {
  String id;
  String name;
  String phone;
  int totalSupplied;
  double totalPaid;
  String notes;

  Seller({
    required this.id,
    required this.name,
    this.phone = '',
    this.totalSupplied = 0,
    this.totalPaid = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'totalSupplied': totalSupplied,
        'totalPaid': totalPaid,
        'notes': notes,
      };

  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        totalSupplied: (json['totalSupplied'] as num?)?.toInt() ?? 0,
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
        notes: json['notes']?.toString() ?? '',
      );
}

/// Account Security & Binds Model
class BindRecord {
  String id;
  String idRecordId;
  String idName;
  String gmail;
  String recoveryEmail;
  String phone;
  String cooldownDate;
  String status; // 'Secure' | 'Cooldown' | 'Vulnerable' | 'Pending'
  Map<String, bool> securityChecklist;

  BindRecord({
    required this.id,
    required this.idRecordId,
    required this.idName,
    this.gmail = '',
    this.recoveryEmail = '',
    this.phone = '',
    this.cooldownDate = '',
    this.status = 'Secure',
    Map<String, bool>? securityChecklist,
  }) : securityChecklist = securityChecklist ?? {
          'twoFactorOn': true,
          'recoveryPhoneRemoved': true,
          'signedOutOfDevices': true,
          'backupCodesSaved': true,
          'buyerVerified': false,
        };

  Map<String, dynamic> toJson() => {
        'id': id,
        'idRecordId': idRecordId,
        'idName': idName,
        'gmail': gmail,
        'recoveryEmail': recoveryEmail,
        'phone': phone,
        'cooldownDate': cooldownDate,
        'status': status,
        'securityChecklist': securityChecklist,
      };

  factory BindRecord.fromJson(Map<String, dynamic> json) => BindRecord(
        id: json['id']?.toString() ?? '',
        idRecordId: json['idRecordId']?.toString() ?? '',
        idName: json['idName']?.toString() ?? '',
        gmail: json['gmail']?.toString() ?? '',
        recoveryEmail: json['recoveryEmail']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        cooldownDate: json['cooldownDate']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Secure',
        securityChecklist: (json['securityChecklist'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v == true)) ??
            {},
      );
}

/// App Configuration Settings
class AppSettings {
  String storeName;
  String storePhone;
  String currencySymbol;
  String reminderTemplate;
  String ownerEmail;

  AppSettings({
    this.storeName = 'ALONE ID SALE',
    this.storePhone = '+91 98765 43210',
    this.currencySymbol = 'Rs.',
    this.reminderTemplate = 'Dear {name}, reminder for Free Fire ID: {idName}. Total balance due: {amount}. Due date: {dueDate}. Please pay soon. Thank you!',
    this.ownerEmail = 'sanchuthan000@gmail.com',
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'storePhone': storePhone,
        'currencySymbol': currencySymbol,
        'reminderTemplate': reminderTemplate,
        'ownerEmail': ownerEmail,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        storeName: json['storeName']?.toString() ?? 'ALONE ID SALE',
        storePhone: json['storePhone']?.toString() ?? '+91 98765 43210',
        currencySymbol: json['currencySymbol']?.toString() ?? 'Rs.',
        reminderTemplate: json['reminderTemplate']?.toString() ?? '',
        ownerEmail: json['ownerEmail']?.toString() ?? 'sanchuthan000@gmail.com',
      );
}

