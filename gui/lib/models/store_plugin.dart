// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

class StorePlugin {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final bool isVerified;
  final String? downloadUrl;
  final List<String> tags;

  const StorePlugin({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    this.isVerified = false,
    this.downloadUrl,
    this.tags = const [],
  });

  factory StorePlugin.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? [];
    return StorePlugin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      downloadUrl: json['downloadUrl'] as String?,
      tags: rawTags.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'isVerified': isVerified,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      'tags': tags,
    };
  }
}
