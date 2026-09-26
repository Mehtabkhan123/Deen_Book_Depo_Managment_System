class AppConstants {
  AppConstants._();

  static const String appName = 'Offline Wholesale Book Management System';
  static const String appShortName = 'Wholesale Books Desktop';
  static const String appVersion = '1.0.0';

  // Local SQLite Database
  static const String databaseName = 'wholesale_book_management.db';
  static const int databaseVersion = 2;

  // Local storage subfolder
  static const String appDataFolder = 'WholesaleBookManagement';
  static const String dbFolder = 'databases';

  // Offline Flag
  static const bool isOfflineOnly = true;
}
