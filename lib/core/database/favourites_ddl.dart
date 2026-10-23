/// Shared by [AppDatabase] (beforeOpen) and the upgrade step in
/// DatabaseUpgrade, so both always create the table identically.
const favouritesTableDdl = '''
CREATE TABLE IF NOT EXISTS favourites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  station_id INTEGER NOT NULL UNIQUE REFERENCES stations(id)
)''';
