import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/stock_movement.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../domain/constants/stock_movement_types.dart';
import '../../domain/repositories/stock_movement_repository.dart';
import '../../domain/services/stock_service.dart';

/// Concrete implementation of [StockService] enforcing atomic inventory mutations
class InventoryStockService implements StockService {
  final BookRepository bookRepository;
  final StockMovementRepository movementRepository;
  final DatabaseHelper _dbHelper;

  InventoryStockService({
    required this.bookRepository,
    required this.movementRepository,
    DatabaseHelper? dbHelper,
  })  : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<int> getCurrentStock(int bookId, {DatabaseExecutor? executor}) async {
    final book = await bookRepository.getById(bookId, executor: executor);
    if (book == null) {
      throw NotFoundException('Book with ID $bookId not found.');
    }
    return book.stockQuantity;
  }

  @override
  Future<StockMovement> increaseStock({
    required int bookId,
    required int quantity,
    required String movementType,
    String? referenceType,
    int? referenceId,
    String? notes,
    DatabaseExecutor? executor,
  }) async {
    if (quantity <= 0) {
      throw const ValidationException('Increase quantity must be greater than zero.');
    }

    Future<StockMovement> run(DatabaseExecutor exec) async {
      final book = await bookRepository.getById(bookId, executor: exec);
      if (book == null) {
        throw NotFoundException('Book with ID $bookId not found.');
      }

      final prevStock = book.stockQuantity;
      final newStock = prevStock + quantity;

      await bookRepository.updateStock(bookId, newStock, executor: exec);

      final movement = StockMovement(
        bookId: bookId,
        movementType: movementType,
        quantity: quantity,
        referenceType: referenceType,
        referenceId: referenceId,
        previousStock: prevStock,
        newStock: newStock,
        movementDate: DateTime.now().toIso8601String(),
        notes: notes,
      );

      final movementId = await movementRepository.create(movement, executor: exec);
      return movement.copyWith(id: movementId);
    }

    if (executor != null) {
      return await run(executor);
    } else {
      return await _dbHelper.transaction<StockMovement>((txn) => run(txn));
    }
  }

  @override
  Future<StockMovement> decreaseStock({
    required int bookId,
    required int quantity,
    required String movementType,
    String? referenceType,
    int? referenceId,
    String? notes,
    DatabaseExecutor? executor,
  }) async {
    if (quantity <= 0) {
      throw const ValidationException('Deduction quantity must be greater than zero.');
    }

    Future<StockMovement> run(DatabaseExecutor exec) async {
      final book = await bookRepository.getById(bookId, executor: exec);
      if (book == null) {
        throw NotFoundException('Book with ID $bookId not found.');
      }

      final prevStock = book.stockQuantity;
      if (prevStock < quantity) {
        throw InsufficientStockException(
          bookId: bookId,
          bookName: book.name,
          requestedQuantity: quantity,
          availableStock: prevStock,
        );
      }

      final newStock = prevStock - quantity;
      await bookRepository.updateStock(bookId, newStock, executor: exec);

      final movement = StockMovement(
        bookId: bookId,
        movementType: movementType,
        quantity: quantity,
        referenceType: referenceType,
        referenceId: referenceId,
        previousStock: prevStock,
        newStock: newStock,
        movementDate: DateTime.now().toIso8601String(),
        notes: notes,
      );

      final movementId = await movementRepository.create(movement, executor: exec);
      return movement.copyWith(id: movementId);
    }

    if (executor != null) {
      return await run(executor);
    } else {
      return await _dbHelper.transaction<StockMovement>((txn) => run(txn));
    }
  }

  @override
  Future<StockMovement> adjustStock({
    required int bookId,
    required int newQuantity,
    String? notes,
    DatabaseExecutor? executor,
  }) async {
    if (newQuantity < 0) {
      throw const ValidationException('Adjusted stock quantity cannot be negative.');
    }

    Future<StockMovement> run(DatabaseExecutor exec) async {
      final book = await bookRepository.getById(bookId, executor: exec);
      if (book == null) {
        throw NotFoundException('Book with ID $bookId not found.');
      }

      final prevStock = book.stockQuantity;
      final diff = newQuantity - prevStock;
      final movementType = diff >= 0
          ? StockMovementTypes.adjustmentIn
          : StockMovementTypes.adjustmentOut;

      await bookRepository.updateStock(bookId, newQuantity, executor: exec);

      final movement = StockMovement(
        bookId: bookId,
        movementType: movementType,
        quantity: diff.abs(),
        referenceType: 'MANUAL_ADJUSTMENT',
        referenceId: null,
        previousStock: prevStock,
        newStock: newQuantity,
        movementDate: DateTime.now().toIso8601String(),
        notes: notes ?? 'Manual stock adjustment to $newQuantity',
      );

      final movementId = await movementRepository.create(movement, executor: exec);
      return movement.copyWith(id: movementId);
    }

    if (executor != null) {
      return await run(executor);
    } else {
      return await _dbHelper.transaction<StockMovement>((txn) => run(txn));
    }
  }

  @override
  Future<List<StockMovement>> getStockMovements({int? limit, int? offset}) {
    return movementRepository.getAll(limit: limit, offset: offset);
  }

  @override
  Future<List<StockMovement>> getMovementsForBook(int bookId, {int? limit, int? offset}) {
    return movementRepository.getByBookId(bookId, limit: limit, offset: offset);
  }

  @override
  Future<List<Book>> getLowStockBooks() {
    return bookRepository.getLowStockBooks();
  }
}
