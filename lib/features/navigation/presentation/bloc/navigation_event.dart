abstract class NavigationEvent {
  const NavigationEvent();
}

/// Dispatched to navigate to a new section in the desktop application
class NavigateTo extends NavigationEvent {
  final String destinationId;

  const NavigateTo(this.destinationId);
}

/// Dispatched to toggle the desktop sidebar between expanded and compact icon-only mode
class ToggleSidebar extends NavigationEvent {
  const ToggleSidebar();
}

/// Alias for NavigateTo
typedef SelectDestination = NavigateTo;
