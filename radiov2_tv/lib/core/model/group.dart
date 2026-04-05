class Group {
  final int id;
  final String name;
  final int? categoryId;
  final int stationCount;

  const Group({
    required this.id,
    required this.name,
    this.categoryId,
    this.stationCount = 0,
  });
}
