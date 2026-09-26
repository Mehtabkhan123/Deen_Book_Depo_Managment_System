import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import 'fast_billing_screen.dart';
import 'upload_product_screen.dart';
import 'client_debt_ledger_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final DbService dbService;

  const MainNavigationShell({super.key, required this.dbService});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _activeTabIndex = 0;
  final DateFormat _dateHeaderFormat = DateFormat('EEEE, dd MMMM yyyy');

  final List<String> _tabTitles = [
    'POS Billing Counter (Fast Wholesale Billing Desk)',
    'Upload / Stock Entry (Catalog & Packaging Specifications)',
    'Client Debt Ledgers (Accounts Receivable & Credit Limits)',
  ];

  void _seedCatalog() async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.dbService.seedInitialDataIfEmpty();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Wholesale catalog and sample accounts seeded successfully!'),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Fixed Sidebar Panel (260px wide, deep indigo)
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E), // Deep Indigo
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Branding Header Emblem
                _buildBrandingHeader(),

                const SizedBox(height: 16),

                // 2. Reactive Module Toggle List Options
                _buildSidebarNavItem(
                  index: 0,
                  icon: Icons.point_of_sale,
                  title: 'POS Billing Counter',
                  subtitle: 'High-speed wholesale sales',
                ),
                _buildSidebarNavItem(
                  index: 1,
                  icon: Icons.add_business,
                  title: 'Upload / Stock Entry',
                  subtitle: 'Catalog & packaging setup',
                ),
                _buildSidebarNavItem(
                  index: 2,
                  icon: Icons.account_balance_wallet,
                  title: 'Client Debt Ledgers',
                  subtitle: 'Credit accounts & ledgers',
                ),

                const Spacer(),

                // 3. Database Utility & System Status
                _buildSidebarFooter(),
              ],
            ),
          ),

          // Right Dynamic Expandable Content Loader
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Global Status & Header Bar
                _buildTopAppBar(),

                // Active Module View
                Expanded(
                  child: IndexedStack(
                    index: _activeTabIndex,
                    children: [
                      FastBillingScreen(dbService: widget.dbService),
                      UploadProductScreen(dbService: widget.dbService),
                      ClientDebtLedgerScreen(dbService: widget.dbService),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF141B6B), // Slightly darker indigo header
        border: Border(bottom: BorderSide(color: Color(0xFF283593), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.menu_book, color: Color(0xFF1A237E), size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEEN BOOK DEPO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'WHOLESALE ERP • POS',
                  style: TextStyle(
                    color: Color(0xFFC5CAE9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _activeTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: isSelected ? const Color(0xFF283593) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _activeTabIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFFC5CAE9),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFE8EAF6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFC5CAE9) : const Color(0xFF9FA8DA),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF141B6B),
        border: Border(top: BorderSide(color: Color(0xFF283593), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Seed Demo Data Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFD54F),
              side: const BorderSide(color: Color(0xFFFFD54F), width: 0.8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.dataset, size: 16),
            label: const Text('Seed Sample Catalog', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _seedCatalog,
          ),
          const SizedBox(height: 12),

          // Database Status Indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.dbService.isOfflineIsarActive
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.dbService.isOfflineIsarActive
                      ? 'Offline Local Mode (Isar DB)'
                      : 'Web Preview (In-Memory DB)',
                  style: const TextStyle(color: Color(0xFFE8EAF6), fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.dbService.isOfflineIsarActive
                ? 'Target Platform: Windows & macOS Native'
                : 'Target: Windows Desktop (Edge Preview)',
            style: const TextStyle(color: Color(0xFF9FA8DA), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _tabTitles[_activeTabIndex],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _dateHeaderFormat.format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.print, size: 14, color: Color(0xFF1A237E)),
                    SizedBox(width: 4),
                    Text(
                      'A4 Spool Ready',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
