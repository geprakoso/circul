import '../profile/editable_profile.dart';
import 'profile_remote_data_source.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository implements ProfileRemoteDataSource {
  bool get hasActiveSession;

  Future<EditableProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  });

  Future<EditableProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<bool> isUsernameTaken(String username);

  Future<void> signOut();
}
