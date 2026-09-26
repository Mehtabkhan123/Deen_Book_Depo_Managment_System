import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/customer_model.dart';
import '../models/debt_ledger_model.dart';
import '../services/db_service.dart';

class ClientDebtLedgerScreen extends StatefulWidget {
  final DbService dbService;

  const ClientDebtLedgerScreen({super.key, required this.dbService});

  @override
  State<ClientDebtLedgerScreen> createState() => _ClientDebtLedgerScreenState();
}

class _ClientDebtLedgerScreenState extends State<ClientDebtLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  List<DebtLedgerEntry> _ledgerEntries = [];

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final NumberFormat _currency = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    final list = widget.dbService.getAllCustomers();
    setState(() {
      _customers = list;
      if (_selectedCustomer == null && list.isNotEmpty) {
        _selectCustomer(list.first);
      } else if (_selectedCustomer != null) {
        final currentId = _selectedCustomer!.id;
        final updated = list.where((c) => c.id == currentId).toList();
        if (updated.isNotEmpty) {
          _selectCustomer(updated.first);
        }
      }
    });
  }

  void _selectCustomer(CustomerModel customer) {
    setState(() {
      _selectedCustomer = customer;
      _ledgerEntries = widget.dbService.getCustomerLedger(customer.id);
    });
  }

  List<CustomerModel> get _filteredCustomers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.shopOrInstitutionName?.toLowerCase().contains(q) ?? false) ||
          (c.phone?.contains(q) ?? false);
    }).toList();
  }

  // Dialog to register a new wholesale client
  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final shopCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '100000');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF1A237E)),
              SizedBox(width: 8),
              Text('Register Wholesale Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Client / Representative Name', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: shopCtrl,
                      decoration: const InputDecoration(labelText: 'Shop / Academy / Institution Name', prefixIcon: Icon(Icons.store)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Phone Number', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Business Address / City', prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: limitCtrl,
                      decoration: const InputDecoration(labelText: 'Approved Credit Line Limit (Rs.)', prefixIcon: Icon(Icons.credit_score)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      validator: (v) => v == null || double.tryParse(v.trim()) == null ? 'Valid amount required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final customer = CustomerModel()
                    ..name = nameCtrl.text.trim()
                    ..shopOrInstitutionName = shopCtrl.text.trim().isNotEmpty ? shopCtrl.text.trim() : null
                    ..phone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null
                    ..address = addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null
                    ..creditLimit = double.parse(limitCtrl.text.trim())
                    ..currentDebtBalance = 0.0;

                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.dbService.saveCustomer(customer);
                  if (mounted) {
                    navigator.pop();
                    _loadCustomers();
                    _selectCustomer(customer);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Client ${customer.name} registered successfully!')),
                    );
                  }
                }
              },
              child: const Text('Register Client'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to record cash or bank payment against client debt
  void _showRecordPaymentDialog() {
    if (_selectedCustomer == null) return;

    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: _selectedCustomer!.currentDebtBalance.toStringAsFixed(2));
    final noteCtrl = TextEditingController();
    String paymentMethod = 'Cash Settlement';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  const Icon(Icons.payments, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  Text('Record Payment: ${_selectedCustomer!.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Outstanding Debt Due:'),
                            Text(
                              'Rs. ${_currency.format(_selectedCustomer!.currentDebtBalance)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount Received (Rs.)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter amount';
                          final val = double.tryParse(v.trim());
                          if (val == null || val <= 0) return 'Must be greater than 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment Instrument'),
                        items: const [
                          DropdownMenuItem(value: 'Cash Settlement', child: Text('Cash Settlement')),
                          DropdownMenuItem(value: 'Online Bank Transfer', child: Text('Online Bank Transfer')),
                          DropdownMenuItem(value: 'Cheque Clearance', child: Text('Cheque Clearance')),
                          DropdownMenuItem(value: 'Promissory Adjustment', child: Text('Promissory Adjustment')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => paymentMethod = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reference Note / Receipt # (Optional)',
                          prefixIcon: Icon(Icons.receipt),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final amount = double.parse(amountCtrl.text.trim());
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await widget.dbService.recordCustomerPayment(
                        customerId: _selectedCustomer!.id,
                        amount: amount,
                        paymentMethod: paymentMethod,
                        referenceNote: noteCtrl.text.trim(),
                      );
                      if (mounted) {
                        navigator.pop();
                        _loadCustomers();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Payment of Rs. ${_currency.format(amount)} recorded for ${_selectedCustomer!.name}!'),
                            backgroundColor: const Color(0xFF1B5E20),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Post Payment & Update Ledger'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6FA),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Client Directory List (35% width)
          Expanded(
            flex: 4,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    // Header & Add Client Button
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Color(0xFF1A237E)),
                        const SizedBox(width: 8),
                        const Text(
                          'Wholesale Clients',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Client', style: TextStyle(fontSize: 12)),
                          onPressed: _showAddCustomerDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search client by name or phone...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Divider(height: 20),

                    // Client List
                    Expanded(
                      child: _filteredCustomers.isEmpty
                          ? Center(
                              child: Text('No clients found', style: TextStyle(color: Colors.grey.shade600)),
                            )
                          : ListView.separated(
                              itemCount: _filteredCustomers.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final client = _filteredCustomers[index];
                                final isSelected = _selectedCustomer?.id == client.id;
                                final hasDebt = client.currentDebtBalance > 0;

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFFE8EAF6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  dense: true,
                                  onTap: () => _selectCustomer(client),
                                  leading: CircleAvatar(
                                    backgroundColor: hasDebt ? Colors.red.shade100 : Colors.green.shade100,
                                    child: Icon(
                                      Icons.person,
                                      color: hasDebt ? Colors.red.shade900 : Colors.green.shade900,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    client.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    client.shopOrInstitutionName ?? client.phone ?? 'Wholesale Account',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${_currency.format(client.currentDebtBalance)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: hasDebt ? Colors.red.shade900 : Colors.green.shade900,
                                        ),
                                      ),
                                      Text(
                                        'Limit: ${_currency.format(client.creditLimit)}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Right: Active Ledger & Transaction History (65% width)
          Expanded(
            flex: 7,
            child: _selectedCustomer == null
                ? const Card(child: Center(child: Text('Select a customer to view ledger')))
                : Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Client Profile & Debt Summary Header
                          _buildClientSummaryHeader(),
                          const Divider(height: 24),

                          // Ledger History Table Header & Actions
                          Row(
                            children: [
                              const Icon(Icons.history, color: Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              const Text(
                                'Credit Line & Debt Ledger History',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.price_check, size: 18),
                                label: const Text('Record Customer Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _showRecordPaymentDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Ledger Table
                          Expanded(
                            child: _ledgerEntries.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_outlined, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text('No debt or payment ledger records found.', style: TextStyle(color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ListView.separated(
                                        itemCount: _ledgerEntries.length,
                                        separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final entry = _ledgerEntries[index];
                                          final isDebit = entry.debitAmount > 0;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                            child: Row(
                                              children: [
                                                // Date
                                                SizedBox(
                                                  width: 140,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(_dateFormat.format(entry.timestamp), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                      if (entry.invoiceNumber != null)
                                                        Text(entry.invoiceNumber!, style: TextStyle(fontSize: 10, color: Colors.indigo.shade700)),
                                                    ],
                                                  ),
                                                ),

                                                // Description
                                                Expanded(
                                                  child: Text(
                                                    entry.description,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),

                                                // Debit (Added Debt)
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    isDebit ? '+ Rs. ${_currency.format(entry.debitAmount)}' : '-',
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: isDebit ? Colors.red.shade900 : Colors.black54,
                                                    ),
                                                  ),
                                                ),

                                                // Credit (Payment Paid)
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    !isDebit ? '- Rs. ${_currency.format(entry.creditAmount)}' : '-',
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: !isDebit ? const Color(0xFF1B5E20) : Colors.black54,
                                                    ),
                                                  ),
                                                ),

                                                // Running Balance
                                                SizedBox(
                                                  width: 130,
                                                  child: Text(
                                                    'Rs. ${_currency.format(entry.runningBalance)}',
                                                    textAlign: TextAlign.end,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: Color(0xFF1A237E),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSummaryHeader() {
    final client = _selectedCustomer!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Client Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 2),
              Text(
                '${client.shopOrInstitutionName ?? "Wholesale Account"} • ${client.phone ?? "No phone"} • ${client.address ?? "Urdu Bazaar"}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
              ),
            ],
          ),

          // Balances & Limit
          Row(
            children: [
              _metricBox('Credit Limit', 'Rs. ${_currency.format(client.creditLimit)}', Colors.black87),
              const SizedBox(width: 16),
              _metricBox('Current Outstanding Debt', 'Rs. ${_currency.format(client.currentDebtBalance)}', Colors.red.shade900),
              const SizedBox(width: 16),
              _metricBox('Available Credit', 'Rs. ${_currency.format(client.availableCredit)}', const Color(0xFF1B5E20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
