import '../profile/editable_profile.dart';
import 'profile_remote_data_source.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthEmailVerificationPending extends AuthFailure {
  const AuthEmailVerificationPending(this.email)
    : super('Email belum diverifikasi. Kode verifikasi baru sudah dikirim.');

  final String email;
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

  Future<void> resendEmailVerification(String email);

  Future<void> verifyEmailOtp({required String email, required String token});

  Future<bool> isEmailTaken(String email);

  Future<bool> isUsernameTaken(String username);

  Future<void> signOut();
}
