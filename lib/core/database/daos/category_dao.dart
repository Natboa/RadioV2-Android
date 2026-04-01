import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/station_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)]))
        .get();
  }
}
