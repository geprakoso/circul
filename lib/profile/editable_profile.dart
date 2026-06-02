class EditableProfile {
  const EditableProfile({
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    this.imagePath,
  });

  final String name;
  final String username;
  final String bio;
  final String location;
  final String? imagePath;

  EditableProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? imagePath,
  }) {
    return EditableProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EditableProfile &&
            name == other.name &&
            username == other.username &&
            bio == other.bio &&
            location == other.location &&
            imagePath == other.imagePath;
  }

  @override
  int get hashCode => Object.hash(name, username, bio, location, imagePath);
}
