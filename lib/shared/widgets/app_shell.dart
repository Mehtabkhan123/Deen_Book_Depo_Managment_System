import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/routing/app_destinations.dart';
import '../../core/theme/app_colors.dart';
import '../../features/books/presentation/pages/books_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../features/purchases/presentation/pages/purchases_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import 'placeholder_view.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// Main Application Shell for Windows Desktop
/// Connects NavigationBloc with Sidebar, TopBar, and dynamic module content
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        final activeDest = state.activeDestination;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Collapsible Desktop Sidebar
              Sidebar(
                activeId: state.activeDestinationId,
                isCollapsed: state.isSidebarCollapsed,
                onSelectDestination: (id) {
                  context.read<NavigationBloc>().add(NavigateTo(id));
                },
                onToggleCollapse: () {
                  context.read<NavigationBloc>().add(const ToggleSidebar());
                },
              ),

              // Right Main Area
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    TopBar(
                      activeDestination: activeDest,
                      onSettingsTap: () {
                        context
                            .read<NavigationBloc>()
                            .add(const NavigateTo(AppDestinations.settings));
                      },
                    ),

                    // Main Content View
                    Expanded(
                      child: _buildContent(state.activeDestinationId, activeDest),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(String activeId, NavDestination destination) {
    switch (activeId) {
      case AppDestinations.dashboard:
        return const DashboardPage();
      case AppDestinations.categories:
        return const CategoriesPage();
      case AppDestinations.books:
        return const BooksPage();
      case AppDestinations.customers:
        return const CustomersPage();
      case AppDestinations.suppliers:
        return const SuppliersPage();
      case AppDestinations.purchases:
        return const PurchasesPage();
      case AppDestinations.sales:
        return const SalesPage();
      case AppDestinations.inventory:
        return const InventoryPage();
      default:
        return ModulePlaceholderPage(
          key: ValueKey(destination.id),
          destination: destination,
        );
    }
  }
}
