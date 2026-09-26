import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:deen_book_depo/core/constants/app_constants.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/utils/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DatabaseService resolves and creates production database file on Windows', () async {
    DatabaseService.configureFfi();

    final db = await DatabaseService.instance.init();
    final path = DatabaseService.instance.databasePath!;

    AppLogger.info('>>> PRODUCTION LOCAL DB PATH: $path');
    expect(db.isOpen, isTrue);
    expect(path.endsWith(AppConstants.databaseName), isTrue);

    final file = File(path);
    expect(await file.exists(), isTrue, reason: 'Physical database file exists on disk');

    final tables = await DatabaseService.instance.getExistingTableNames();
    AppLogger.info('>>> REGISTERED SCHEMA TABLES (${tables.length}): ${tables.join(', ')}');
    expect(tables.length, greaterThanOrEqualTo(13));

    await DatabaseService.instance.close();
  });
}
