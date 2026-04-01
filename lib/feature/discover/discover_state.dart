import '../../core/model/category.dart';

sealed class DiscoverUiState {
  const DiscoverUiState();
}

class DiscoverLoading extends DiscoverUiState {
  const DiscoverLoading();
}

class DiscoverSuccess extends DiscoverUiState {
  final List<CategoryWithGroups> categories;
  const DiscoverSuccess(this.categories);
}

class DiscoverError extends DiscoverUiState {
  final String message;
  const DiscoverError(this.message);
}
