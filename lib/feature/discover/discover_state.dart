import '../../core/model/category.dart';
import '../../core/model/group.dart';

sealed class DiscoverUiState {
  const DiscoverUiState();
}

class DiscoverLoading extends DiscoverUiState {
  const DiscoverLoading();
}

class DiscoverSuccess extends DiscoverUiState {
  final List<CategoryWithGroups> categories;
  /// Non-null while a search query is active — flat list of matching groups.
  final List<Group>? searchResults;

  const DiscoverSuccess(this.categories, {this.searchResults});

  bool get isSearching => searchResults != null;
}

class DiscoverError extends DiscoverUiState {
  final String message;
  const DiscoverError(this.message);
}
