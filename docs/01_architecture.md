# 01 — Architecture Overview

> **Scope**: System architecture, layer responsibilities, dependency rules, design decisions  
> **Audience**: Semua developer  
> **Terakhir diupdate**: 2026-06-09

---

## Ringkasan Sistem

Circul adalah Flutter app untuk aksi lingkungan berbasis komunitas. Arsitektur saat ini:

- **Frontend**: Flutter (Material 3)
- **Local Storage**: SQLite via `sqflite`
- **Remote Backend**: Supabase (Auth + PostgreSQL + RLS)
- **Map**: OpenStreetMap tiles via `flutter_map` + Geoapify
- **Location**: `geolocator` + `geocoding` + Nominatim API
- **Media**: `image_picker` untuk camera capture

---

## Diagram Layer

```
┌──────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                     │
│                                                          │
│   Screens (home_screen, map_screen, profile_screen, ...) │
│   Widgets (feed_post_card, chip_button, sarah_avatar)    │
│   Bottom Navigation (CirculShell, CirculBottomNav)        │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                     STATE MANAGEMENT                      │
│                                                          │
│   StatefulWidget + setState (manual callback chains)     │
│   _CirculShellState sebagai state coordinator             │
│   RefreshToken pattern untuk trigger rebuild              │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                      DATA LAYER                          │
│                                                          │
│   Repositories:                                          │
│   ├── FeedPostRepository (SQLite)                        │
│   ├── CommentRepository (SQLite)                         │
│   ├── SavedPostRepository (SQLite)                       │
│   ├── LikedPostRepository (SQLite)                       │
│   └── UserRepository (SQLite + Supabase)                 │
│                                                          │
│   Data Sources:                                          │
│   ├── CirculDatabase (SQLite singleton)                   │
│   ├── SupabaseAuthRepository (Supabase Auth + Profiles)  │
│   └── ProfileRemoteDataSource (interface)                │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                    EXTERNAL SERVICES                      │
│                                                          │
│   ├── Supabase Auth (email/password, OTP verification)   │
│   ├── Supabase Database (profiles table + RLS)           │
│   ├── Geoapify / OSM (map tiles)                         │
│   ├── Nominatim (geocoding + location search)            │
│   ├── Geolocator (device GPS)                            │
│   └── ImagePicker (device camera)                        │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Dependency Rules

### Aturan Import

```
screens → widgets, repositories, models, shared, core
widgets → models, shared, core
repositories → database, models, data sources
database → (standalone, no project imports)
models → (standalone, no project imports)
core → (standalone, flutter SDK only)
shared → core, models
```

### Larangan

| Tidak Boleh | Alasan |
|---|---|
| Widget import repository langsung | Gunakan callback atau parameter dari screen |
| Repository import widget | Data layer tidak boleh tahu tentang UI |
| Screen A import screen B secara langsung (kecuali navigasi) | Coupling antar fitur |
| Shared widget import feature-specific code | Shared harus general purpose |

### Pengecualian yang Dibolehkan

| Kasus | Alasan |
|---|---|
| `event_screen.dart` import `ActivityCard` dari `map/widgets/` | ActivityCard dipakai di 2 fitur berbeda, idealnya pindah ke shared |
| `search_screen.dart` import `feed_post_card.dart` | Search menampilkan hasil post dengan kartu yang sama |

---

## State Management Pattern

### Saat Ini: Lifted State + Callback Chains

State coordinator utama ada di `_CirculShellState` (`lib/main.dart`):

```dart
// State yang dikelola di shell
var _index = 0;                              // Tab aktif
var _homeRefreshToken = 0;                   // Trigger reload feed
var _profileRefreshToken = 0;                // Trigger reload profil
var _mapCurrentLocationRefreshToken = 0;     // Trigger re-center map
var _searchResetToken = 0;                   // Trigger reset search
var _currentUserProfile = ...;               // Profil user aktif
MapFocusedCheckIn? _focusedCheckIn;          // Check-in yang di-focus di map
final _issueClusters = <MapIssueCluster>[];  // Heat map clusters
```

### Refresh Token Pattern

Saat data berubah (post baru, like, save, comment), shell increment `refreshToken` → child widget cek di `didUpdateWidget` → jika berubah, reload data.

```dart
// Shell menaikkan token
void _refreshPostConsumers() {
  setState(() {
    _homeRefreshToken++;
    _profileRefreshToken++;
  });
}

// Child cek perubahan
@override
void didUpdateWidget(covariant HomeScreen oldWidget) {
  if (widget.refreshToken != oldWidget.refreshToken) {
    _reload(); // fetch ulang data
  }
}
```

### Callback Chain Flow

```
HomeScreen.onPostCreated
  → _CirculShellState._refreshPostConsumers
    → increment _homeRefreshToken, _profileRefreshToken
      → HomeScreen.didUpdateWidget → reload
      → ProfileScreen.didUpdateWidget → reload
```

---

## Navigation Pattern

### Saat Ini: Manual Navigator + IndexedStack

- **Tab navigation**: `IndexedStack` di `CirculShell` — semua 5 tab screen hidup bersamaan, state dipertahankan saat pindah tab.
- **Push navigation**: `Navigator.of(context).push(MaterialPageRoute(...))` untuk fullscreen screens (NewPost, Comments, CaptureResult, EditProfile, WelcomeFlow).
- **Auth gate**: `_AuthGate` widget menentukan apakah tampilkan `WelcomeFlow` atau `CirculShell` berdasarkan `authRepository.hasActiveSession`.

### Route Table

| Tujuan | Cara Navigasi | Kembali |
|---|---|---|
| Home → NewPost | `Navigator.push` → `NewPostScreen` | `pop(true)` jika sukses, `pop()` jika batal |
| Home → Comments | `Navigator.push` → `CommentScreen` | `pop(true)` jika ada perubahan |
| Home → ImageViewer | `Navigator.push` → `UploadedImageFullscreenPage` | `pop()` |
| Map → CaptureResult | `Navigator.push` → `CaptureResultScreen` | `pop(true)` jika submit |
| Profile → EditProfile | `Navigator.push` → `EditProfileScreen` | `pop(updatedProfile)` |
| Profile → Achievements | `Navigator.push` → `AchievementScreen` | `pop()` |
| Profile → WelcomeFlow | `Navigator.push` → `WelcomeFlow` (re-view) | `pop()` |
| Tab switch | `_handleTabChanged(index)` → `setState` → `IndexedStack` | N/A |

---

## Design Decisions Log

| Tanggal | Keputusan | Alasan | Diputuskan Oleh |
|---|---|---|---|
| 2026-05-18 | Flutter sebagai framework | Cross-platform, single codebase | Founder |
| 2026-05-18 | SQLite untuk local storage | Offline-first, no server needed untuk MVP | Founder |
| 2026-05-21 | OpenStreetMap + Geoapify tiles | Gratis, open source, API key bisa diganti | Founder |
| 2026-05-25 | Feature-based folder structure | Scalable, self-contained modules | Founder |
| 2026-06-07 | Supabase untuk auth & profiles | Managed backend, RLS built-in, auth SDK | Founder |
| 2026-06-07 | Email OTP verification | SMTP provider-agnostic, cocok untuk dev | Founder |
| 2026-06-09 | Callback chain state management | Sederhana untuk satu developer, bisa refactor nanti | Founder |

---

## Risiko Arsitektur yang Diketahui

| # | Risiko | Severity | Deskripsi |
|---|---|---|---|
| R1 | God files | 🔴 Tinggi | `map_screen.dart` (2756 baris), `welcome_flow.dart` (2512 baris), `search_screen.dart` (1313 baris) |
| R2 | Callback chain complexity | 🟡 Sedang | 14+ callback methods di `_CirculShellState`, sulit di-trace |
| R3 | Tidak ada DI framework | 🟡 Sedang | Repository dibuat manual, sulit mock untuk test |
| R4 | `sync_status` belum dipakai | 🟢 Info | Column ada di SQLite tapi belum ada sync logic |
| R5 | Hardcoded Supabase credentials | 🟡 Sedang | URL dan anon key ada di source, meskipun bisa di-override via `--dart-define` |
| R6 | Map tile API key di source | 🟡 Sedang | Geoapify key hardcoded, perlu pindah ke environment variable |
