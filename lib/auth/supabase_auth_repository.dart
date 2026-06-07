import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../profile/editable_profile.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<AuthRepository?> initializeFromEnvironment() async {
    if (url.trim().isEmpty || anonKey.trim().isEmpty) return null;

    await supabase.Supabase.initialize(url: url, publishableKey: anonKey);
    return SupabaseAuthRepository(supabase.Supabase.instance.client);
  }

  final supabase.SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  bool get hasActiveSession => _client.auth.currentSession != null;

  @override
  Future<EditableProfile?> fetchCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return _profileFromRow(row);
    } catch (error) {
      throw AuthFailure(_messageFromError(error));
    }
  }

  @override
  Future<Set<String>> fetchTakenUsernames({String excludingUserId = ''}) async {
    try {
      final query = _client.from('profiles').select('id, username');
      final rows = excludingUserId.trim().isEmpty
          ? await query
          : await query.neq('id', excludingUserId.trim());

      return rows.map((row) => row['username']).whereType<String>().toSet();
    } catch (error) {
      throw AuthFailure(_messageFromError(error));
    }
  }

  @override
  Future<void> saveCurrentProfile(EditableProfile profile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthFailure('Silakan login untuk memperbarui profil.');
    }

    try {
      await _client
          .from('profiles')
          .update(_profilePayload(profile))
          .eq('id', userId);
    } catch (error) {
      throw AuthFailure(_messageFromError(error));
    }
  }

  @override
  Future<EditableProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await fetchCurrentProfile();
      if (profile != null) return profile;

      throw const AuthFailure('Profil belum tersedia untuk akun ini.');
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure(_messageFromError(error));
    }
  }

  @override
  Future<EditableProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final profile = EditableProfile(
      name: name.trim(),
      username: _cleanUsername(username),
      bio: '',
      location: '',
    );

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': profile.name, 'username': profile.username},
      );
      final userId = response.user?.id ?? currentUserId;
      if (userId == null) {
        throw const AuthFailure('Akun dibuat, tetapi sesi belum aktif.');
      }
      if (currentUserId == null) {
        throw const AuthFailure(
          'Akun dibuat. Silakan verifikasi email lalu login.',
        );
      }

      await _client.from('profiles').upsert({
        'id': userId,
        ..._profilePayload(profile),
      });
      return profile;
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure(_messageFromError(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  EditableProfile _profileFromRow(Map<String, dynamic> row) {
    return EditableProfile(
      name: (row['name'] as String?)?.trim().isNotEmpty == true
          ? row['name'] as String
          : 'Circul User',
      username: row['username'] as String,
      bio: (row['bio'] as String?) ?? '',
      location: (row['location'] as String?) ?? '',
      imagePath: row['image_path'] as String?,
    );
  }

  Map<String, Object?> _profilePayload(EditableProfile profile) {
    return {
      'name': profile.name.trim(),
      'username': _cleanUsername(profile.username),
      'bio': profile.bio.trim(),
      'location': profile.location.trim(),
      'image_path': profile.imagePath?.trim().isEmpty == true
          ? null
          : profile.imagePath,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String _cleanUsername(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '');
  }

  String _messageFromError(Object error) {
    final rawMessage = switch (error) {
      supabase.AuthException(:final message) => message,
      supabase.PostgrestException(:final message) => message,
      AuthFailure(:final message) => message,
      _ => error.toString(),
    };
    final message = rawMessage.toLowerCase();
    if (message.contains('duplicate') ||
        message.contains('profiles_username') ||
        message.contains('unique')) {
      return 'Username sudah dipakai.';
    }
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Email atau password tidak sesuai.';
    }
    return rawMessage;
  }
}
