import '../../core/model/category.dart';

sealed class DiscoverTvUiState {
  const DiscoverTvUiState();
}

class DiscoverTvLoading extends DiscoverTvUiState {
  const DiscoverTvLoading();
}

class DiscoverTvSuccess extends DiscoverTvUiState {
  final List<CategoryWithGroups> categories;
  const DiscoverTvSuccess(this.categories);
}

class DiscoverTvError extends DiscoverTvUiState {
  final String message;
  const DiscoverTvError(this.message);
}
