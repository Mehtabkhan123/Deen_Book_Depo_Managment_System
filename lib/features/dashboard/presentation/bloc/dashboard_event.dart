abstract class DashboardEvent {
  const DashboardEvent();
}

/// Dispatched to load real-time metrics and recent activities
class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

/// Dispatched to refresh dashboard metrics
class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}

// Preserve backward-compatibility for existing tests/code
typedef LoadDashboardMetrics = LoadDashboard;
typedef RefreshDashboardMetrics = RefreshDashboard;
