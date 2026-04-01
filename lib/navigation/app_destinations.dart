enum AppDestination {
  browse(label: 'Browse', icon: 0xe8b6),   // Icons.radio
  discover(label: 'Discover', icon: 0xe87c), // Icons.explore
  favourites(label: 'Favourites', icon: 0xe87d); // Icons.favorite

  const AppDestination({required this.label, required this.icon});

  final String label;
  final int icon;
}

class AppRoutes {
  static const browse = '/browse';
  static const discover = '/discover';
  static const favourites = '/favourites';
  static const groupDetail = '/discover/group/:groupId';

  static String groupDetailPath(int groupId) =>
      '/discover/group/$groupId';
}
