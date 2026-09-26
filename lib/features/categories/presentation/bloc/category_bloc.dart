import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/category.dart';
import '../../domain/repositories/category_repository.dart';

// ==========================================
// Events
// ==========================================
abstract class CategoryEvent {
  const CategoryEvent();
}

class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

class RefreshCategories extends CategoryEvent {
  const RefreshCategories();
}

class SearchCategories extends CategoryEvent {
  final String query;
  const SearchCategories(this.query);
}

class AddCategory extends CategoryEvent {
  final Category category;
  const AddCategory(this.category);
}

class UpdateCategory extends CategoryEvent {
  final Category category;
  const UpdateCategory(this.category);
}

class DeleteCategory extends CategoryEvent {
  final int id;
  const DeleteCategory(this.id);
}

class ClearCategoryMessages extends CategoryEvent {
  const ClearCategoryMessages();
}

// ==========================================
// States
// ==========================================
abstract class CategoryState {
  const CategoryState();
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final String searchQuery;
  final String? successMessage;
  final String? errorMessage;

  const CategoryLoaded(
    this.categories, {
    this.searchQuery = '',
    this.successMessage,
    this.errorMessage,
  });

  CategoryLoaded copyWith({
    List<Category>? categories,
    String? searchQuery,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return CategoryLoaded(
      categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
}

// ==========================================
// BLoC
// ==========================================
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository}) : super(const CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<RefreshCategories>(_onRefreshCategories);
    on<SearchCategories>(_onSearchCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<ClearCategoryMessages>(_onClearMessages);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());
    try {
      final categories = await categoryRepository.getAll();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError('Failed to load categories: $e'));
    }
  }

  Future<void> _onRefreshCategories(RefreshCategories event, Emitter<CategoryState> emit) async {
    final currentQuery = state is CategoryLoaded ? (state as CategoryLoaded).searchQuery : '';
    try {
      final categories = currentQuery.isEmpty
          ? await categoryRepository.getAll()
          : await categoryRepository.search(currentQuery);
      emit(CategoryLoaded(categories, searchQuery: currentQuery));
    } catch (e) {
      emit(CategoryError('Failed to refresh categories: $e'));
    }
  }

  Future<void> _onSearchCategories(SearchCategories event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());
    try {
      final categories = await categoryRepository.search(event.query);
      emit(CategoryLoaded(categories, searchQuery: event.query));
    } catch (e) {
      emit(CategoryError('Failed to search categories: $e'));
    }
  }

  Future<void> _onAddCategory(AddCategory event, Emitter<CategoryState> emit) async {
    try {
      await categoryRepository.create(event.category);
      final currentQuery = state is CategoryLoaded ? (state as CategoryLoaded).searchQuery : '';
      final categories = currentQuery.isEmpty
          ? await categoryRepository.getAll()
          : await categoryRepository.search(currentQuery);
      emit(CategoryLoaded(
        categories,
        searchQuery: currentQuery,
        successMessage: 'Category "${event.category.name}" created successfully.',
      ));
    } on AppException catch (e) {
      if (state is CategoryLoaded) {
        emit((state as CategoryLoaded).copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(CategoryError(e.message));
      }
    } catch (e) {
      if (state is CategoryLoaded) {
        emit((state as CategoryLoaded).copyWith(errorMessage: 'Failed to create category: $e', clearSuccess: true));
      } else {
        emit(CategoryError('Failed to create category: $e'));
      }
    }
  }

  Future<void> _onUpdateCategory(UpdateCategory event, Emitter<CategoryState> emit) async {
    try {
      await categoryRepository.update(event.category);
      final currentQuery = state is CategoryLoaded ? (state as CategoryLoaded).searchQuery : '';
      final categories = currentQuery.isEmpty
          ? await categoryRepository.getAll()
          : await categoryRepository.search(currentQuery);
      emit(CategoryLoaded(
        categories,
        searchQuery: currentQuery,
        successMessage: 'Category "${event.category.name}" updated successfully.',
      ));
    } on AppException catch (e) {
      if (state is CategoryLoaded) {
        emit((state as CategoryLoaded).copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(CategoryError(e.message));
      }
    } catch (e) {
      if (state is CategoryLoaded) {
        emit((state as CategoryLoaded).copyWith(errorMessage: 'Failed to update category: $e', clearSuccess: true));
      } else {
        emit(CategoryError('Failed to update category: $e'));
      }
    }
  }

  Future<void> _onDeleteCategory(DeleteCategory event, Emitter<CategoryState> emit) async {
    try {
      await categoryRepository.delete(event.id);
      final currentQuery = state is CategoryLoaded ? (state as CategoryLoaded).searchQuery : '';
      final categories = currentQuery.isEmpty
          ? await categoryRepository.getAll()
          : await categoryRepository.search(currentQuery);
      emit(CategoryLoaded(
        categories,
        searchQuery: currentQuery,
        successMessage: 'Category deleted successfully.',
      ));
    } on AppException catch (e) {
      if (state is CategoryLoaded) {
        emit((state as CategoryLoaded).copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(CategoryError(e.message));
      }
    } catch (e) {
      if (state is CategoryLoaded) {
        emit((state as CategoryLoaded).copyWith(errorMessage: 'Failed to delete category: $e', clearSuccess: true));
      } else {
        emit(CategoryError('Failed to delete category: $e'));
      }
    }
  }

  void _onClearMessages(ClearCategoryMessages event, Emitter<CategoryState> emit) {
    if (state is CategoryLoaded) {
      emit((state as CategoryLoaded).copyWith(clearSuccess: true, clearError: true));
    }
  }
}
