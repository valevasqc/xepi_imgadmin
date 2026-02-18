import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch sales data within date range with filters
  Future<List<Map<String, dynamic>>> getSales({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryCode,
    String? productBarcode,
    String? paymentMethod,
    String? saleType,
  }) async {
    Query query = _firestore.collection('sales');

    // Date range filter
    query = query
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    List<Map<String, dynamic>> sales = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['saleId'] = doc.id;

      // Apply additional filters in memory (Firestore composite index limitations)
      bool include = true;

      if (paymentMethod != null && data['paymentMethod'] != paymentMethod) {
        include = false;
      }

      if (saleType != null && data['saleType'] != saleType) {
        include = false;
      }

      // Filter by category - check if any item matches
      if (categoryCode != null) {
        final items = data['items'] as List<dynamic>? ?? [];
        include = items.any((item) => item['categoryCode'] == categoryCode);
      }

      // Filter by product
      if (productBarcode != null) {
        final items = data['items'] as List<dynamic>? ?? [];
        include = items.any((item) => item['barcode'] == productBarcode);
      }

      if (include) {
        sales.add(data);
      }
    }

    return sales;
  }

  // Fetch expenses data within date range
  Future<List<Map<String, dynamic>>> getExpenses({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryType,
  }) async {
    Query query = _firestore
        .collection('expenses')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    List<Map<String, dynamic>> expenses = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['expenseId'] = doc.id;

      // Apply category type filter
      if (categoryType == null || data['categoryType'] == categoryType) {
        expenses.add(data);
      }
    }

    return expenses;
  }

  // Get pending cash by source
  Future<Map<String, double>> getPendingCash() async {
    final snapshot = await _firestore.collection('pendingCash').get();
    Map<String, double> pendingCash = {
      'store': 0,
      'mensajero': 0,
      'forza': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final source = data['source'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      if (source != null && pendingCash.containsKey(source)) {
        pendingCash[source] = amount;
      }
    }

    return pendingCash;
  }

  // Get all categories for filter dropdown
  Future<List<Map<String, dynamic>>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    List<Map<String, dynamic>> categories = [];

    for (var doc in snapshot.docs) {
      final subcategoriesSnapshot = await doc.reference.collection('subcategories').get();
      
      for (var subDoc in subcategoriesSnapshot.docs) {
        final data = subDoc.data();
        categories.add({
          'code': data['code'],
          'name': '${data['primaryCategory']} - ${data['subcategoryName']}',
          'primaryCategory': data['primaryCategory'],
          'subcategoryName': data['subcategoryName'],
        });
      }
    }

    categories.sort((a, b) => a['name'].compareTo(b['name']));
    return categories;
  }

  // Get products for filter (search functionality)
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    // Firestore doesn't support full-text search, so we fetch and filter
    final snapshot = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .limit(50)
        .get();

    List<Map<String, dynamic>> products = [];
    final lowerQuery = query.toLowerCase();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] as String?)?.toLowerCase() ?? '';
      final barcode = data['barcode'] as String? ?? '';

      if (name.contains(lowerQuery) || barcode.contains(query)) {
        products.add({
          'barcode': barcode,
          'name': data['name'],
        });
      }
    }

    return products;
  }

  // Calculate sales analytics
  Map<String, dynamic> calculateSalesAnalytics(List<Map<String, dynamic>> sales) {
    double totalRevenue = 0;
    int totalSalesCount = sales.length;
    int totalProductsSold = 0;
    Map<String, double> salesByCategory = {};
    Map<String, int> productQuantities = {};
    Map<String, double> productRevenue = {};
    Map<String, String> productNames = {};
    Map<String, int> salesByPaymentMethod = {};
    Map<String, int> salesBySaleType = {};
    Map<String, double> dailySales = {};

    for (var sale in sales) {
      final total = (sale['total'] as num?)?.toDouble() ?? 0;
      totalRevenue += total;

      // Payment method breakdown
      final paymentMethod = sale['paymentMethod'] as String? ?? 'unknown';
      salesByPaymentMethod[paymentMethod] = (salesByPaymentMethod[paymentMethod] ?? 0) + 1;

      // Sale type breakdown
      final saleType = sale['saleType'] as String? ?? 'unknown';
      salesBySaleType[saleType] = (salesBySaleType[saleType] ?? 0) + 1;

      // Daily sales for trend chart
      final createdAt = (sale['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        dailySales[dateKey] = (dailySales[dateKey] ?? 0) + total;
      }

      // Process items
      final items = sale['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
        final barcode = item['barcode'] as String? ?? '';
        final name = item['name'] as String? ?? 'Unknown';
        final categoryCode = item['categoryCode'] as String?;

        totalProductsSold += quantity;

        // Product sales tracking
        productQuantities[barcode] = (productQuantities[barcode] ?? 0) + quantity;
        productRevenue[barcode] = (productRevenue[barcode] ?? 0) + subtotal;
        productNames[barcode] = name;

        // Category sales tracking
        if (categoryCode != null) {
          salesByCategory[categoryCode] = (salesByCategory[categoryCode] ?? 0) + subtotal;
        }
      }
    }

    // Calculate average ticket
    double avgTicket = totalSalesCount > 0 ? totalRevenue / totalSalesCount : 0;

    // Sort products by revenue
    List<Map<String, dynamic>> topProducts = [];
    productRevenue.forEach((barcode, revenue) {
      topProducts.add({
        'barcode': barcode,
        'name': productNames[barcode],
        'quantity': productQuantities[barcode],
        'revenue': revenue,
      });
    });
    topProducts.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    return {
      'totalRevenue': totalRevenue,
      'totalSalesCount': totalSalesCount,
      'totalProductsSold': totalProductsSold,
      'avgTicket': avgTicket,
      'salesByCategory': salesByCategory,
      'topProducts': topProducts,
      'salesByPaymentMethod': salesByPaymentMethod,
      'salesBySaleType': salesBySaleType,
      'dailySales': dailySales,
    };
  }

  // Calculate expenses analytics
  Map<String, dynamic> calculateExpensesAnalytics(List<Map<String, dynamic>> expenses) {
    double totalExpenses = 0;
    Map<String, double> expensesByCategory = {};
    Map<String, double> expensesByType = {
      'operativo': 0,
      'no_operativo': 0,
    };
    Map<String, double> dailyExpenses = {};

    for (var expense in expenses) {
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
      totalExpenses += amount;

      final category = expense['category'] as String? ?? 'Sin categoría';
      expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;

      final categoryType = expense['categoryType'] as String?;
      if (categoryType != null && (categoryType == 'operativo' || categoryType == 'no_operativo')) {
        expensesByType[categoryType] = (expensesByType[categoryType] ?? 0) + amount;
      }

      // Daily expenses for trend chart
      final createdAt = (expense['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        dailyExpenses[dateKey] = (dailyExpenses[dateKey] ?? 0) + amount;
      }
    }

    return {
      'totalExpenses': totalExpenses,
      'expensesByCategory': expensesByCategory,
      'expensesByType': expensesByType,
      'dailyExpenses': dailyExpenses,
    };
  }

  // Get bank accounts for revenue/expense breakdown
  Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final snapshot = await _firestore
        .collection('bankAccounts')
        .where('isActive', isEqualTo: true)
        .orderBy('bankName')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Calculate revenue by bank account
  Map<String, double> calculateRevenueByAccount(
    List<Map<String, dynamic>> sales,
    List<Map<String, dynamic>> bankAccounts,
  ) {
    Map<String, double> revenueByAccount = {
      'efectivo': 0,
    };

    // Initialize all bank accounts with 0
    for (var account in bankAccounts) {
      revenueByAccount[account['id']] = 0;
    }

    for (var sale in sales) {
      final total = (sale['total'] as num?)?.toDouble() ?? 0;
      final paymentMethod = sale['paymentMethod'] as String?;
      final destinationAccount = sale['destinationAccount'] as String?;

      if (paymentMethod == 'efectivo') {
        revenueByAccount['efectivo'] = (revenueByAccount['efectivo'] ?? 0) + total;
      } else if (destinationAccount != null && revenueByAccount.containsKey(destinationAccount)) {
        revenueByAccount[destinationAccount] = revenueByAccount[destinationAccount]! + total;
      }
    }

    return revenueByAccount;
  }

  // Calculate expenses by payment source
  Map<String, dynamic> calculateExpensesByPaymentSource(
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> bankAccounts,
  ) {
    Map<String, double> expensesBySource = {
      'efectivo': 0,
    };

    // Initialize all bank accounts with 0
    for (var account in bankAccounts) {
      expensesBySource[account['id']] = 0;
    }

    for (var expense in expenses) {
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
      final paymentSource = expense['paymentSource'] as String? ?? 'efectivo';

      if (paymentSource == 'efectivo') {
        expensesBySource['efectivo'] = (expensesBySource['efectivo'] ?? 0) + amount;
      } else if (expensesBySource.containsKey(paymentSource)) {
        expensesBySource[paymentSource] = expensesBySource[paymentSource]! + amount;
      }
    }

    return expensesBySource;
  }
}
