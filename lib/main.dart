import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/di/injection.dart';
import 'core/theme/theme.dart';
import 'core/utils/app_logger.dart';
import 'features/books/presentation/bloc/books_bloc.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/customers/presentation/bloc/customer_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';
import 'features/navigation/presentation/bloc/navigation_bloc.dart';
import 'features/purchases/presentation/bloc/purchase_bloc.dart';
import 'features/sales/presentation/bloc/sales_bloc.dart';
import 'features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'shared/widgets/app_shell.dart';
import 'shared/widgets/error_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platformDesc = kIsWeb
      ? 'Web Browser Preview'
      : 'Windows Desktop (${Platform.operatingSystem})';

  AppLogger.info('====================================================');
  AppLogger.info('  Starting ${AppConstants.appName}  ');
  AppLogger.info('  Platform: $platformDesc | Engine: SQLite FFI    ');
  AppLogger.info('====================================================');

  String? initError;

  try {
    // 1. Configure SQLite FFI loader for Windows Desktop
    DatabaseService.configureFfi();

    // 2. Initialize Centralized Dependency Injection Container
    await Injection.instance.init();
    AppLogger.success('Dependency Injection container and SQLite connection initialized.');
  } catch (e, stack) {
    AppLogger.error('Critical initialization failure: $e', e, stack);
    initError = e.toString();
  }

  runApp(
    WholesaleBookApp(
      initializationError: initError,
    ),
  );
}

/// Root Application Widget configured for Windows Desktop with BLoC State Management
class WholesaleBookApp extends StatelessWidget {
  final String? initializationError;

  const WholesaleBookApp({
    super.key,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    if (initializationError != null) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: ErrorState(
            title: 'Application Initialization Failed',
            message: initializationError!,
          ),
        ),
      );
    }

    final di = Injection.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationBloc>(
          create: (_) => NavigationBloc(),
        ),
        BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(
            bookRepository: di.bookRepository,
            saleRepository: di.saleRepository,
            purchaseRepository: di.purchaseRepository,
            customerRepository: di.customerRepository,
            supplierRepository: di.supplierRepository,
            customerLedgerService: di.customerLedgerService,
            supplierLedgerService: di.supplierLedgerService,
            databaseHelper: di.databaseHelper,
            expenseRepository: di.expenseRepository,
            customerPaymentRepository: di.customerPaymentRepository,
            supplierPaymentRepository: di.supplierPaymentRepository,
          )..add(const LoadDashboard()),
        ),
        BlocProvider<BooksBloc>(
          create: (_) => BooksBloc(bookRepository: di.bookRepository),
        ),
        BlocProvider<CategoryBloc>(
          create: (_) => CategoryBloc(categoryRepository: di.categoryRepository),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(
            customerRepository: di.customerRepository,
            ledgerService: di.customerLedgerService,
          ),
        ),
        BlocProvider<SupplierBloc>(
          create: (_) => SupplierBloc(
            supplierRepository: di.supplierRepository,
            ledgerService: di.supplierLedgerService,
          ),
        ),
        BlocProvider<PurchaseBloc>(
          create: (_) => PurchaseBloc(
            purchaseRepository: di.purchaseRepository,
            supplierRepository: di.supplierRepository,
            bookRepository: di.bookRepository,
          ),
        ),
        BlocProvider<SalesBloc>(
          create: (_) => SalesBloc(
            saleRepository: di.saleRepository,
            customerRepository: di.customerRepository,
            bookRepository: di.bookRepository,
          ),
        ),
        BlocProvider<InventoryBloc>(
          create: (_) => InventoryBloc(
            bookRepository: di.bookRepository,
            categoryRepository: di.categoryRepository,
            stockMovementRepository: di.stockMovementRepository,
            stockService: di.stockService,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppShell(),
      ),
    );
  }
}
