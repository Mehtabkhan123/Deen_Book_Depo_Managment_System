import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';
import 'database_tables.dart';

/// Core SQLite Database Service for Windows Desktop and Web Preview environments
class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  Database? _database;
  String? _databasePath;

  /// Returns active SQLite database instance
  Database get database {
    if (_database == null || !_database!.isOpen) {
      throw const AppDatabaseException(
        'Database has not been initialized. Call DatabaseService.instance.init() first.',
        code: 'DB_NOT_INITIALIZED',
      );
    }
    return _database!;
  }

  /// Whether database is currently open
  bool get isOpen => _database != null && _database!.isOpen;

  /// Absolute local file path of the database on the host machine
  String? get databasePath => _databasePath;

  static bool _ffiConfigured = false;

  /// Configures SQLite FFI loader for desktop platforms and web browser preview
  static void configureFfi() {
    if (_ffiConfigured) return;

    if (kIsWeb) {
      AppLogger.info('Initializing SQLite Web FFI engine for browser runtime...');
      try {
        databaseFactory = databaseFactoryFfiWeb;
      } catch (_) {
        databaseFactory = databaseFactoryFfiWebNoWebWorker;
      }
      _ffiConfigured = true;
      AppLogger.success('SQLite Web FFI successfully bound.');
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      AppLogger.info('Initializing SQLite FFI engine for desktop runtime (${Platform.operatingSystem})...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiConfigured = true;
      AppLogger.success('SQLite FFI successfully bound to databaseFactoryFfi.');
    }
  }

  /// Initializes and opens the local SQLite database
  Future<Database> init({String? overridePath}) async {
    try {
      if (_database != null && _database!.isOpen) {
        AppLogger.info('Database already open at: $_databasePath');
        return _database!;
      }

      // Configure FFI for current platform (Desktop or Web)
      configureFfi();

      final String fullDbPath = overridePath ?? await resolveDatabasePath();
      _databasePath = fullDbPath;

      AppLogger.info('Opening local SQLite database: $fullDbPath');

      _database = await databaseFactory.openDatabase(
        fullDbPath,
        options: OpenDatabaseOptions(
          version: AppConstants.databaseVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: (db) {
            AppLogger.success('Database opened successfully: $fullDbPath');
          },
        ),
      );

      return _database!;
    } catch (e, stack) {
      AppLogger.error('Failed to initialize database: $e', e, stack);
      throw AppDatabaseException(
        'Failed to initialize SQLite database: $e',
        code: 'DB_INIT_FAILED',
        details: e,
      );
    }
  }

  /// Resolves the local database path on Windows desktop (or Web virtual storage)
  Future<String> resolveDatabasePath() async {
    if (kIsWeb) {
      // In web browser preview mode, sqflite_common_ffi_web uses an IndexedDB virtual database
      return AppConstants.databaseName;
    }

    try {
      if (Platform.isWindows) {
        // Standard Windows AppData directory: C:\Users\<User>\AppData\Roaming\WholesaleBookManagement\databases
        final String? appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final Directory dbDir = Directory(
            p.join(appData, AppConstants.appDataFolder, AppConstants.dbFolder),
          );

          if (!await dbDir.exists()) {
            await dbDir.create(recursive: true);
            AppLogger.info('Created Windows database storage folder at: ${dbDir.path}');
          }

          return p.join(dbDir.path, AppConstants.databaseName);
        }

        // Fallback to path_provider application support directory
        final Directory appSupportDir = await getApplicationSupportDirectory();
        final Directory dbDir = Directory(
          p.join(appSupportDir.path, AppConstants.appDataFolder, AppConstants.dbFolder),
        );

        if (!await dbDir.exists()) {
          await dbDir.create(recursive: true);
          AppLogger.info('Created database storage folder at: ${dbDir.path}');
        }

        return p.join(dbDir.path, AppConstants.databaseName);
      } else {
        // Fallback for non-Windows testing / runtime
        final String defaultPath = await databaseFactory.getDatabasesPath();
        final Directory dir = Directory(defaultPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return p.join(defaultPath, AppConstants.databaseName);
      }
    } catch (e) {
      AppLogger.warning('Could not resolve application support directory ($e). Using default databases path.');
      final String fallbackPath = await databaseFactory.getDatabasesPath();
      return p.join(fallbackPath, AppConstants.databaseName);
    }
  }

  /// Enforces foreign keys and high-speed WAL mode for Windows desktop
  Future<void> _onConfigure(Database db) async {
    AppLogger.debug('Configuring SQLite PRAGMA settings...');
    await db.execute('PRAGMA foreign_keys = ON;');
    if (!kIsWeb) {
      await db.execute('PRAGMA journal_mode = WAL;');
      await db.execute('PRAGMA synchronous = NORMAL;');
    }
  }

  /// Creates all initial tables and indexes
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating initial database schema (v$version)...');
    try {
      await DatabaseTables.createAllTables(db);
      AppLogger.success('All wholesale management tables & indexes created successfully.');
    } catch (e, stack) {
      AppLogger.error('Failed to create database schema: $e', e, stack);
      throw DatabaseMigrationException(
        'Database table creation failed: $e',
        code: 'SCHEMA_CREATION_FAILED',
        details: e,
      );
    }
  }

  /// Migration handler for future schema updates
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database schema from v$oldVersion to v$newVersion...');
    await DatabaseTables.migrate(db, oldVersion, newVersion);
    AppLogger.success('Database schema upgraded successfully to v$newVersion.');
  }

  /// Inspects all tables currently present in the database
  Future<List<String>> getExistingTableNames() async {
    final List<Map<String, dynamic>> tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' ORDER BY name;",
    );
    return tables.map((row) => row['name'] as String).toList();
  }

  /// Closes database connection cleanly
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      final path = _databasePath;
      await _database!.close();
      _database = null;
      AppLogger.info('Database closed: $path');
    }
  }
}
