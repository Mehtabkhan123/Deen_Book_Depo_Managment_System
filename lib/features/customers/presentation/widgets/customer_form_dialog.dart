import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Professional Windows Desktop dialog for creating and editing customer accounts
class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final ValueChanged<Customer> onSave;

  const CustomerFormDialog({
    super.key,
    this.customer,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Customer? customer,
    required ValueChanged<Customer> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CustomerFormDialog(
        customer: customer,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _notesController;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _openingBalanceController = TextEditingController(
      text: c != null ? c.openingBalance.toStringAsFixed(2) : '0.00',
    );
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final trimmedPhone = _phoneController.text.trim();
    final trimmedEmail = _emailController.text.trim();
    final trimmedAddress = _addressController.text.trim();
    final openingBalance =
        double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;
    final trimmedNotes = _notesController.text.trim();

    final customer = Customer(
      id: widget.customer?.id,
      name: trimmedName,
      phone: trimmedPhone.isEmpty ? null : trimmedPhone,
      email: trimmedEmail.isEmpty ? null : trimmedEmail,
      address: trimmedAddress.isEmpty ? null : trimmedAddress,
      openingBalance: openingBalance,
      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      createdAt: widget.customer?.createdAt ?? '',
    );

    widget.onSave(customer);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      backgroundColor: AppColors.surface,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Customer' : 'Add New Customer',
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Update wholesale account details and contact information'
                                : 'Register a new customer account into the wholesale ledger',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
                const SizedBox(height: 16),

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Contact Information
                        _buildSectionHeader('Contact Information', Icons.contact_phone_outlined),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Customer / Business Name *',
                          hint: 'e.g. Al-Madina Book Depot, Oxford Academy',
                          controller: _nameController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Customer name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Phone Number',
                                hint: 'e.g. 0300-1234567',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                label: 'Email Address',
                                hint: 'e.g. contact@bookdepo.pk',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final trimmed = val.trim();
                                    if (!trimmed.contains('@') || !trimmed.contains('.')) {
                                      return 'Enter a valid email address';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Physical Address',
                          hint: 'Shop / School Address, City, Postal Area',
                          controller: _addressController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // SECTION 2: Financial Information
                        _buildSectionHeader('Financial Information', Icons.account_balance_wallet_outlined),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Opening Balance (PKR / Currency) *',
                          hint: '0.00',
                          controller: _openingBalanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Opening balance is required';
                            }
                            final num = double.tryParse(val.trim());
                            if (num == null) {
                              return 'Enter a valid numeric amount';
                            }
                            if (num < 0) {
                              return 'Opening balance cannot be negative';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // SECTION 3: Additional Notes
                        _buildSectionHeader('Additional Information', Icons.notes_rounded),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Internal Notes (Optional)',
                          hint: 'e.g. Special wholesale discount terms, preferred delivery route',
                          controller: _notesController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: isEditing ? 'Save Changes' : 'Create Customer',
                      icon: isEditing ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
