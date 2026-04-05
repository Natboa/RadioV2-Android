import 'group.dart';

class Category {
  final int id;
  final String name;
  final int displayOrder;

  const Category({
    required this.id,
    required this.name,
    required this.displayOrder,
  });
}

class CategoryWithGroups {
  final Category category;
  final List<Group> groups;

  const CategoryWithGroups({required this.category, required this.groups});
}
