class Station {
  final int id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final int groupId;
  final bool isFeatured;
  final bool isFavourite;

  const Station({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    required this.groupId,
    this.isFeatured = false,
    this.isFavourite = false,
  });

  Station copyWith({bool? isFavourite}) {
    return Station(
      id: id,
      name: name,
      streamUrl: streamUrl,
      logoUrl: logoUrl,
      groupId: groupId,
      isFeatured: isFeatured,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}
