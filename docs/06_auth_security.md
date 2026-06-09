# 06 — Auth & Security

> **Scope**: Authentication flow, Supabase configuration, RLS policies, API key management, email verification  
> **Audience**: Backend developer, security reviewer  
> **Terakhir diupdate**: 2026-06-09

---

## Authentication Stack

```
┌───────────────────────────────────────────────────┐
│                  WELCOME FLOW UI                   │
│  (welcome_flow.dart → WelcomeAuthService)          │
├───────────────────────────────────────────────────┤
│            WELCOME AUTH ADAPTER                    │
│  (WelcomeAuthRepositoryAdapter)                    │
│  Adapts AuthRepository → WelcomeAuthService        │
├───────────────────────────────────────────────────┤
│              AUTH REPOSITORY                       │
│  (SupabaseAuthRepository : AuthRepository)         │
├───────────────────────────────────────────────────┤
│           SUPABASE FLUTTER SDK                     │
│  (Supabase.instance.client)                        │
├───────────────────────────────────────────────────┤
│              SUPABASE BACKEND                      │
│  Auth + PostgreSQL + RLS + Edge Functions          │
└───────────────────────────────────────────────────┘
```

---

## Supabase Initialization

File: `lib/main.dart` → `main()`

```dart
final supabaseUrl = const String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://yvniwhawfkibyzymqmkz.supabase.co',
);
final supabaseAnonKey = const String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIs...', // truncated
);

await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
);
```

### Override via Build

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

> ⚠️ **Security Note**: Default credentials ada di source code. Untuk production, HARUS di-override via `--dart-define` dan di-restrict di Supabase dashboard (API Settings → Allowed domains).

---

## Sign Up Flow (Detail)

### Step 1: Validate Email

```dart
// Check apakah email sudah terdaftar
final taken = await authRepository.isEmailTaken(email);
// → Supabase RPC: is_email_taken(check_email)
// → Query: SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = lower(check_email))
```

### Step 2: Validate Username

```dart
// Check apakah username sudah dipakai
final taken = await authRepository.isUsernameTaken(username);
// → Supabase RPC: is_username_taken(check_username)
// → Query: SELECT EXISTS(SELECT 1 FROM profiles WHERE lower(username) = lower(strip_at))
```

### Step 3: Sign Up

```dart
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: 'com.example.circul://login-callback',
  data: {
    'name': name,
    'username': username,
  },
);
```

`data` (metadata) digunakan oleh database trigger `on_auth_user_created_create_profile` untuk auto-create profile record.

### Step 4: Email Verification

Supabase otomatis kirim email verifikasi dengan OTP code (8 digit, configured di Supabase dashboard).

```dart
// User memasukkan OTP 8 digit
await supabase.auth.verifyOTP(
  type: OtpType.email,
  email: email,
  token: otpCode,
);
```

### Step 5: Profile Created

Profile otomatis dibuat oleh Supabase trigger. WelcomeFlow panggil `onComplete()` → UI switch ke CirculShell.

---

## Sign In Flow (Detail)

```dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Post-Sign In: Profile Sync

Setelah sign in berhasil, profile di-fetch dari Supabase dan di-cache ke SQLite:

```dart
// SupabaseAuthRepository._fetchOrCreateProfile()
final data = await supabase
  .from('profiles')
  .select()
  .eq('id', userId)
  .maybeSingle();

if (data != null) {
  return EditableProfile(
    name: data['name'],
    username: data['username'],
    bio: data['bio'] ?? '',
    location: data['location'] ?? '',
    imagePath: data['image_path'],
  );
}
```

### Email Not Verified

Jika user sign in tapi email belum diverifikasi, `SupabaseAuthRepository` mendeteksi dari response dan WelcomeFlow redirect ke `emailVerification` step.

---

## Session Management

### Session Persistence

Supabase SDK menyimpan session token secara otomatis di platform storage (SharedPreferences di Android, Keychain di iOS).

### Session Check

```dart
// Di _AuthGate
bool get hasActiveSession {
  return Supabase.instance.client.auth.currentSession != null;
}
```

### Session Refresh

Supabase SDK otomatis refresh expired tokens menggunakan refresh token.

### Sign Out

```dart
await supabase.auth.signOut();
// → Clear session dari device storage
// → UI kembali ke WelcomeFlow via AuthGate
```

---

## Row Level Security (RLS)

### Table: `profiles`

RLS: **Enabled**

| Policy Name | Operation | Using | With Check |
|---|---|---|---|
| Authenticated users can read profiles | SELECT | `auth.role() = 'authenticated'` | - |
| Users can create their own profile | INSERT | - | `auth.uid() = id` |
| Users can update their own profile | UPDATE | `auth.uid() = id` | `auth.uid() = id` |

**Implikasi:**
- Semua authenticated user bisa baca **semua** profiles (untuk search username, view other users)
- User hanya bisa create/update **profil sendiri**
- Anon (tidak login) **tidak bisa** akses data apapun
- DELETE **tidak diizinkan** (belum ada policy)

### RPC Functions Security

| Function | Security | Access |
|---|---|---|
| `is_email_taken` | `SECURITY DEFINER` | Public (anon + authenticated) |
| `is_username_taken` | `SECURITY DEFINER` | Public (anon + authenticated) |
| `handle_new_user_profile` | `SECURITY DEFINER` | Trigger only (not callable from client) |

`SECURITY DEFINER` = berjalan dengan privileges dari function owner (admin), bukan caller. Ini diperlukan agar `is_email_taken` bisa query `auth.users` yang normalnya tidak accessible dari client.

---

## API Keys & Secrets

### Managed Keys

| Key | Lokasi | Environment Variable | Scope |
|---|---|---|---|
| Supabase URL | `main.dart` (default), `--dart-define` (override) | `SUPABASE_URL` | Backend endpoint |
| Supabase Anon Key | `main.dart` (default), `--dart-define` (override) | `SUPABASE_ANON_KEY` | Public API key (RLS protected) |
| Geoapify Map API Key | `map_screen.dart` (hardcoded) | `MAP_TILE_URL_TEMPLATE` | Map tile rendering |
| App User Agent | `map_screen.dart` (hardcoded) | `APP_USER_AGENT_PACKAGE_NAME` | Nominatim API user agent |

### Security Checklist

| Item | Status | Action |
|---|---|---|
| Supabase anon key di source | ⚠️ Oke untuk dev | Override via `--dart-define` untuk production |
| Geoapify key di source | ⚠️ Oke untuk dev | Restrict key di Geoapify dashboard untuk production |
| RLS enabled pada semua tables | ✅ | - |
| No DELETE policy pada profiles | ✅ (intentional) | User tidak bisa hapus akun via client |
| Email OTP verification enforced | ✅ | - |
| Password requirements enforced client-side | ⚠️ | Tambahkan server-side validation juga |

---

## Email Configuration

### Supabase Email Settings

Diatur di Supabase Dashboard → Authentication → Email:

| Setting | Value | Catatan |
|---|---|---|
| Enable email sign up | ✅ | - |
| Confirm email | ✅ | User harus verifikasi sebelum bisa login |
| OTP expiry | 3600s (1 jam) | Default Supabase |
| OTP length | 8 digit | Custom (default Supabase = 6) |
| Rate limit email sends | 60s cooldown | Enforced di client via `_resendCooldownSeconds = 60` |

### Email Redirect URL

```
com.example.circul://login-callback
```

Didaftarkan di:
- Supabase Dashboard → Authentication → URL Configuration → Redirect URLs
- Android: `AndroidManifest.xml` → intent filter
- iOS: `Info.plist` → URL schemes

---

## Error Types

File: `lib/auth/auth_repository.dart`

```dart
sealed class AuthFailure {
  final String message;
}

class CredentialsFailure extends AuthFailure { ... }  // Wrong email/password
class EmailNotVerified extends AuthFailure { ... }    // Email belum diverifikasi
class NetworkFailure extends AuthFailure { ... }      // Network error
class UnknownFailure extends AuthFailure { ... }      // Catch-all
```

### Error to UI Mapping

| AuthFailure Type | UI Display |
|---|---|
| `CredentialsFailure` | "Incorrect email or password. Please try again." |
| `EmailNotVerified` | Redirect ke OTP verification screen |
| `NetworkFailure` | "Tidak bisa terhubung ke server. Cek koneksi internet." |
| `UnknownFailure` | Show raw error message |

---

## Auth Fallback: Offline Mode

Jika Supabase init gagal (no internet, server down):

```dart
// main.dart
AuthRepository? authRepository;
try {
  await Supabase.initialize(...);
  authRepository = SupabaseAuthRepository();
} catch (_) {
  authRepository = null; // No auth available
}
```

`_AuthGate` behavior saat `authRepository == null`:
- Skip auth → langsung ke `CirculShell` dengan profile default
- WelcomeFlow menggunakan `UnavailableWelcomeAuthService` (semua method no-op)
- App fully functional secara lokal, tapi tidak ada account, sync, atau profile Supabase

---

## Future Security Considerations

| Item | Priority | Deskripsi |
|---|---|---|
| Server-side password validation | 🔴 Tinggi | Saat ini password rules hanya di client |
| Rate limiting auth attempts | 🟡 Sedang | Supabase punya built-in, tapi perlu configure |
| Account deletion | 🟡 Sedang | GDPR requirement — belum ada endpoint |
| Refresh token rotation | 🟢 Rendah | Supabase SDK sudah handle otomatis |
| Social login (Google/Apple) | 🟡 Sedang | UI sudah ada, backend belum disetup |
| Image upload to Supabase Storage | 🟡 Sedang | Saat ini image hanya di local file system |
