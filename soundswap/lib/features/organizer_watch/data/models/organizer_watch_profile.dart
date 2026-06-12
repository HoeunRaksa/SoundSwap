import 'package:soundswap/features/folder_organizer/data/models/organizer_options.dart';

class OrganizerWatchProfile {
  const OrganizerWatchProfile({
    required this.id,
    required this.name,
    this.sourceFolderPath,
    this.destinationFolderPath,
    this.isActive = false,
    this.options = const OrganizerOptions(),
  });

  final String id;
  final String name;
  final String? sourceFolderPath;
  final String? destinationFolderPath;
  final bool isActive;
  final OrganizerOptions options;

  bool get hasRequiredFolders =>
      sourceFolderPath != null && destinationFolderPath != null;

  OrganizerWatchProfile copyWith({
    String? id,
    String? name,
    String? sourceFolderPath,
    String? destinationFolderPath,
    bool? isActive,
    OrganizerOptions? options,
  }) {
    return OrganizerWatchProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFolderPath: sourceFolderPath ?? this.sourceFolderPath,
      destinationFolderPath: destinationFolderPath ?? this.destinationFolderPath,
      isActive: isActive ?? this.isActive,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceFolderPath': sourceFolderPath,
      'destinationFolderPath': destinationFolderPath,
      'isActive': isActive,
      'options': options.toJson(),
    };
  }

  factory OrganizerWatchProfile.fromJson(Map<String, dynamic> json) {
    return OrganizerWatchProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceFolderPath: json['sourceFolderPath'] as String?,
      destinationFolderPath: json['destinationFolderPath'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      options: json['options'] != null
          ? OrganizerOptions.fromJson(json['options'] as Map<String, dynamic>)
          : const OrganizerOptions(),
    );
  }
}
