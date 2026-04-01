import 'package:drift/drift.dart';

class Stations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get streamUrl => text().unique()();
  TextColumn get logoUrl => text().nullable()();
  IntColumn get groupId => integer().references(Groups, #id)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isFeatured => boolean().withDefault(const Constant(false))();
}

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
}

class Favourites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stationId =>
      integer().unique().references(Stations, #id)();
}
