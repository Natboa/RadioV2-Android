import 'package:drift/drift.dart';

class Stations extends Table {
  IntColumn get id => integer().named('Id').autoIncrement()();
  TextColumn get name => text().named('Name')();
  TextColumn get streamUrl => text().named('StreamUrl').unique()();
  TextColumn get logoUrl => text().named('LogoUrl').nullable()();
  IntColumn get groupId => integer().named('GroupId').references(Groups, #id)();
  BoolColumn get isFavorite =>
      boolean().named('IsFavorite').withDefault(const Constant(false))();
  BoolColumn get isFeatured =>
      boolean().named('IsFeatured').withDefault(const Constant(false))();
}

class Groups extends Table {
  IntColumn get id => integer().named('Id').autoIncrement()();
  TextColumn get name => text().named('Name').unique()();
  IntColumn get categoryId =>
      integer().named('CategoryId').nullable().references(Categories, #id)();
}

class Categories extends Table {
  IntColumn get id => integer().named('Id').autoIncrement()();
  TextColumn get name => text().named('Name')();
  IntColumn get displayOrder =>
      integer().named('DisplayOrder').withDefault(const Constant(0))();
}

class Favourites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stationId => integer().unique().references(Stations, #id)();
}
