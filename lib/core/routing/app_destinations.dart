import 'package:flutter/material.dart';

/// Navigation destination item configuration for the desktop sidebar and router
class NavDestination {
  final String id;
  final String title;
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String description;

  const NavDestination({
    required this.id,
    required this.title,
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.description,
  });
}

/// Central catalog of desktop navigation destinations
class AppDestinations {
  AppDestinations._();

  static const String dashboard = 'dashboard';
  static const String books = 'books';
  static const String categories = 'categories';
  static const String customers = 'customers';
  static const String suppliers = 'suppliers';
  static const String purchases = 'purchases';
  static const String sales = 'sales';
  static const String inventory = 'inventory';
  static const String payments = 'payments';
  static const String expenses = 'expenses';
  static const String reports = 'reports';
  static const String settings = 'settings';

  static const List<NavDestination> mainItems = [
    NavDestination(
      id: dashboard,
      title: 'Dashboard',
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      description: 'System metrics, financial overview, and recent activity',
    ),
    NavDestination(
      id: books,
      title: 'Books',
      route: '/books',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      description: 'Book catalog, pricing, and master product records',
    ),
    NavDestination(
      id: categories,
      title: 'Categories',
      route: '/categories',
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
      description: 'Book classification and genre groupings',
    ),
    NavDestination(
      id: customers,
      title: 'Customers',
      route: '/customers',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      description: 'Customer directory, balances, and account statements',
    ),
    NavDestination(
      id: suppliers,
      title: 'Suppliers',
      route: '/suppliers',
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      description: 'Supplier directory, credit payables, and procurement',
    ),
    NavDestination(
      id: purchases,
      title: 'Purchases',
      route: '/purchases',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      description: 'Wholesale inward invoices and stock purchase logs',
    ),
    NavDestination(
      id: sales,
      title: 'Sales',
      route: '/sales',
      icon: Icons.point_of_sale_rounded,
      activeIcon: Icons.point_of_sale_rounded,
      description: 'Wholesale billing, customer invoices, and receipts',
    ),
    NavDestination(
      id: inventory,
      title: 'Inventory',
      route: '/inventory',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      description: 'Real-time stock ledger, audits, and movements',
    ),
    NavDestination(
      id: payments,
      title: 'Payments',
      route: '/payments',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      description: 'Customer receipts and supplier disbursements',
    ),
    NavDestination(
      id: expenses,
      title: 'Expenses',
      route: '/expenses',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      description: 'Petty cash and operational business expenses',
    ),
    NavDestination(
      id: reports,
      title: 'Reports',
      route: '/reports',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      description: 'Sales summaries, stock valuation, and tax ledgers',
    ),
  ];

  static const List<NavDestination> bottomItems = [
    NavDestination(
      id: settings,
      title: 'Settings',
      route: '/settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      description: 'Local database backup, printer, and business profile',
    ),
  ];

  static NavDestination getById(String id) {
    return [...mainItems, ...bottomItems].firstWhere(
      (item) => item.id == id,
      orElse: () => mainItems.first,
    );
  }
}
