import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/book.dart';
import '../../domain/repositories/book_repository.dart';

// ==========================================
// Events
// ==========================================
abstract class BooksEvent {
  const BooksEvent();
}

class LoadBooks extends BooksEvent {
  const LoadBooks();
}

class RefreshBooks extends BooksEvent {
  const RefreshBooks();
}

class SearchBooks extends BooksEvent {
  final String query;
  const SearchBooks(this.query);
}

class FilterBooksByCategory extends BooksEvent {
  final int? categoryId;
  const FilterBooksByCategory(this.categoryId);
}

class AddBook extends BooksEvent {
  final Book book;
  const AddBook(this.book);
}

class UpdateBook extends BooksEvent {
  final Book book;
  const UpdateBook(this.book);
}

class DeleteBook extends BooksEvent {
  final int id;
  const DeleteBook(this.id);
}

class ClearBookMessages extends BooksEvent {
  const ClearBookMessages();
}

// ==========================================
// States
// ==========================================
abstract class BooksState {
  const BooksState();
}

class BooksInitial extends BooksState {
  const BooksInitial();
}

class BooksLoading extends BooksState {
  const BooksLoading();
}

class BooksLoaded extends BooksState {
  final List<Book> books;
  final String searchQuery;
  final int? selectedCategoryId;
  final String? successMessage;
  final String? errorMessage;

  const BooksLoaded(
    this.books, {
    this.searchQuery = '',
    this.selectedCategoryId,
    this.successMessage,
    this.errorMessage,
  });

  BooksLoaded copyWith({
    List<Book>? books,
    String? searchQuery,
    int? selectedCategoryId,
    bool clearCategory = false,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return BooksLoaded(
      books ?? this.books,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BooksError extends BooksState {
  final String message;
  const BooksError(this.message);
}

// ==========================================
// BLoC
// ==========================================
class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final BookRepository bookRepository;

  BooksBloc({required this.bookRepository}) : super(const BooksInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<RefreshBooks>(_onRefreshBooks);
    on<SearchBooks>(_onSearchBooks);
    on<FilterBooksByCategory>(_onFilterByCategory);
    on<AddBook>(_onAddBook);
    on<UpdateBook>(_onUpdateBook);
    on<DeleteBook>(_onDeleteBook);
    on<ClearBookMessages>(_onClearMessages);
  }

  Future<void> _onLoadBooks(LoadBooks event, Emitter<BooksState> emit) async {
    emit(const BooksLoading());
    try {
      final books = await bookRepository.getAll();
      emit(BooksLoaded(books));
    } catch (e) {
      emit(BooksError('Failed to load books: $e'));
    }
  }

  Future<void> _onRefreshBooks(RefreshBooks event, Emitter<BooksState> emit) async {
    final currentQuery = state is BooksLoaded ? (state as BooksLoaded).searchQuery : '';
    final currentCategory = state is BooksLoaded ? (state as BooksLoaded).selectedCategoryId : null;
    try {
      final books = await bookRepository.searchAndFilter(
        query: currentQuery,
        categoryId: currentCategory,
      );
      emit(BooksLoaded(
        books,
        searchQuery: currentQuery,
        selectedCategoryId: currentCategory,
      ));
    } catch (e) {
      emit(BooksError('Failed to refresh books: $e'));
    }
  }

  Future<void> _onSearchBooks(SearchBooks event, Emitter<BooksState> emit) async {
    emit(const BooksLoading());
    final currentCategory = state is BooksLoaded ? (state as BooksLoaded).selectedCategoryId : null;
    try {
      final books = await bookRepository.searchAndFilter(
        query: event.query,
        categoryId: currentCategory,
      );
      emit(BooksLoaded(
        books,
        searchQuery: event.query,
        selectedCategoryId: currentCategory,
      ));
    } catch (e) {
      emit(BooksError('Failed to search books: $e'));
    }
  }

  Future<void> _onFilterByCategory(FilterBooksByCategory event, Emitter<BooksState> emit) async {
    emit(const BooksLoading());
    final currentQuery = state is BooksLoaded ? (state as BooksLoaded).searchQuery : '';
    try {
      final books = await bookRepository.searchAndFilter(
        query: currentQuery,
        categoryId: event.categoryId,
      );
      emit(BooksLoaded(
        books,
        searchQuery: currentQuery,
        selectedCategoryId: event.categoryId,
      ));
    } catch (e) {
      emit(BooksError('Failed to filter books by category: $e'));
    }
  }

  Future<void> _onAddBook(AddBook event, Emitter<BooksState> emit) async {
    try {
      await bookRepository.create(event.book);
      final currentQuery = state is BooksLoaded ? (state as BooksLoaded).searchQuery : '';
      final currentCategory = state is BooksLoaded ? (state as BooksLoaded).selectedCategoryId : null;
      final books = await bookRepository.searchAndFilter(
        query: currentQuery,
        categoryId: currentCategory,
      );
      emit(BooksLoaded(
        books,
        searchQuery: currentQuery,
        selectedCategoryId: currentCategory,
        successMessage: 'Book "${event.book.name}" created successfully.',
      ));
    } on AppException catch (e) {
      if (state is BooksLoaded) {
        emit((state as BooksLoaded).copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(BooksError(e.message));
      }
    } catch (e) {
      if (state is BooksLoaded) {
        emit((state as BooksLoaded).copyWith(errorMessage: 'Failed to create book: $e', clearSuccess: true));
      } else {
        emit(BooksError('Failed to create book: $e'));
      }
    }
  }

  Future<void> _onUpdateBook(UpdateBook event, Emitter<BooksState> emit) async {
    try {
      await bookRepository.update(event.book);
      final currentQuery = state is BooksLoaded ? (state as BooksLoaded).searchQuery : '';
      final currentCategory = state is BooksLoaded ? (state as BooksLoaded).selectedCategoryId : null;
      final books = await bookRepository.searchAndFilter(
        query: currentQuery,
        categoryId: currentCategory,
      );
      emit(BooksLoaded(
        books,
        searchQuery: currentQuery,
        selectedCategoryId: currentCategory,
        successMessage: 'Book "${event.book.name}" updated successfully.',
      ));
    } on AppException catch (e) {
      if (state is BooksLoaded) {
        emit((state as BooksLoaded).copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(BooksError(e.message));
      }
    } catch (e) {
      if (state is BooksLoaded) {
        emit((state as BooksLoaded).copyWith(errorMessage: 'Failed to update book: $e', clearSuccess: true));
      } else {
        emit(BooksError('Failed to update book: $e'));
      }
    }
  }

  Future<void> _onDeleteBook(DeleteBook event, Emitter<BooksState> emit) async {
    try {
      await bookRepository.delete(event.id);
      final currentQuery = state is BooksLoaded ? (state as BooksLoaded).searchQuery : '';
      final currentCategory = state is BooksLoaded ? (state as BooksLoaded).selectedCategoryId : null;
      final books = await bookRepository.searchAndFilter(
        query: currentQuery,
        categoryId: currentCategory,
      );
      emit(BooksLoaded(
        books,
        searchQuery: currentQuery,
        selectedCategoryId: currentCategory,
        successMessage: 'Book deleted successfully.',
      ));
    } on AppException catch (e) {
      if (state is BooksLoaded) {
        emit((state as BooksLoaded).copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(BooksError(e.message));
      }
    } catch (e) {
      if (state is BooksLoaded) {
        emit((state as BooksLoaded).copyWith(errorMessage: 'Failed to delete book: $e', clearSuccess: true));
      } else {
        emit(BooksError('Failed to delete book: $e'));
      }
    }
  }

  void _onClearMessages(ClearBookMessages event, Emitter<BooksState> emit) {
    if (state is BooksLoaded) {
      emit((state as BooksLoaded).copyWith(clearSuccess: true, clearError: true));
    }
  }
}
