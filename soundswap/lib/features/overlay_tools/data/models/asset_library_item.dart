class AssetLibraryItem {
  const AssetLibraryItem({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String path;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AssetLibraryItem.fromJson(Map<String, Object?> json) {
    return AssetLibraryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Asset',
      path: json['path'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  AssetLibraryItem copyWith({String? name, String? path}) {
    return AssetLibraryItem(
      id: id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt,
    );
  }
}
