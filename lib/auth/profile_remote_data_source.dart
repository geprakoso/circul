import '../profile/editable_profile.dart';

abstract class ProfileRemoteDataSource {
  String? get currentUserId;

  Future<EditableProfile?> fetchCurrentProfile();

  Future<Set<String>> fetchTakenUsernames({String excludingUserId = ''});

  Future<void> saveCurrentProfile(EditableProfile profile);
}
