import '../../../../core/routing/app_destinations.dart';

/// State of desktop shell navigation
class NavigationState {
  final String activeDestinationId;
  final bool isSidebarCollapsed;

  const NavigationState({
    required this.activeDestinationId,
    this.isSidebarCollapsed = false,
  });

  NavDestination get activeDestination => AppDestinations.getById(activeDestinationId);

  NavigationState copyWith({
    String? activeDestinationId,
    bool? isSidebarCollapsed,
  }) {
    return NavigationState(
      activeDestinationId: activeDestinationId ?? this.activeDestinationId,
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
    );
  }
}
