# 03 — Project Structure & Conventions

> **Scope**: Folder structure, file naming, widget naming, import conventions  
> **Audience**: Semua developer  
> **Terakhir diupdate**: 2026-06-09

---

## Folder Structure Aktual

```
lib/
├── main.dart                      # Entry point, CirculApp, CirculShell, BottomNav, AuthGate
│
├── core/
│   ├── constants.dart             # Warna global: kCirculGreen, kInk, kMuted, kLine, kSoftGreen
│   └── app_assets.dart            # Asset path constants
│
├── shared/
│   ├── shared_widgets.dart        # Barrel file — export semua shared widgets
│   ├── animated_like_icon.dart    # AnimatedLikeIcon (Lottie animation)
│   ├── chip_button.dart           # ChipButton
│   ├── circul_header.dart         # CirculHeader, CirculLogo, CirculFullLogo
│   ├── notification_icon.dart     # NotificationIcon
│   ├── relative_timestamp.dart    # formatRelativeTimestamp() function
│   ├── sarah_avatar.dart          # SarahAvatar (default user avatar)
│   ├── search_field_shell.dart    # SearchFieldShell
│   └── section_title.dart         # SectionTitle
│
├── auth/
│   ├── auth_repository.dart       # AuthRepository abstract class + AuthFailure
│   ├── supabase_auth_repository.dart  # SupabaseAuthRepository implementation
│   └── profile_remote_data_source.dart # ProfileRemoteDataSource interface
│
├── welcome/
│   └── welcome_flow.dart          # WelcomeFlow + semua screen onboarding (2512 baris)
│
├── home/
│   ├── home_screen.dart           # HomeScreen + _HomeHeader + _HomeComposerEntry
│   └── widgets/
│       ├── feed_post_card.dart    # FeedPostCard + sub-widgets
│       └── post_options_bottom_sheet.dart  # showPostOptionsBottomSheet()
│
├── new_post/
│   ├── new_post_screen.dart       # NewPostScreen + composer logic
│   └── widgets/
│       ├── compose_header.dart
│       ├── compose_footer.dart
│       ├── compose_tools.dart
│       ├── topic_autocomplete.dart
│       └── attachment_media_strip.dart
│
├── comments/
│   └── comment_screen.dart        # CommentScreen + comment composer
│
├── check_in/
│   └── capture_result_screen.dart # CaptureResultScreen (camera capture flow)
│
├── map/
│   ├── map_screen.dart            # MapScreen + semua map logic (2756 baris)
│   └── widgets/
│       ├── activity_sheet.dart    # ActivitySheet, ActivityCard
│       ├── impact_legend.dart     # ImpactLegend
│       ├── location_bubble.dart   # LocationBubble, UserLocationPulse
│       ├── map_marker.dart        # MapMarker
│       ├── map_square_button.dart # MapSquareButton
│       └── waste_map_painter.dart # WasteMapPainter (CustomPainter)
│
├── search/
│   ├── search_screen.dart         # SearchScreen + semua search logic (1313 baris)
│   └── widgets/
│       └── topic_row.dart         # TopicRow
│
├── event/
│   └── event_screen.dart          # EventScreen (placeholder, 286 bytes)
│
├── image_viewer/
│   └── uploaded_image_fullscreen_page.dart  # UploadedImageFullscreenPage
│
├── profile/
│   ├── profile_screen.dart        # ProfileScreen + tabs + post/comment/saved views
│   ├── edit_profile_screen.dart   # EditProfileScreen (form)
│   ├── achievement_screen.dart    # AchievementScreen (badge gallery)
│   ├── editable_profile.dart      # EditableProfile model class
│   └── widgets/
│       ├── achievement_badge.dart
│       ├── profile_meta.dart
│       ├── profile_placeholder.dart
│       ├── profile_stats.dart
│       └── segmented_profile_tabs.dart
│
├── mock_data.dart                 # FeedPost, Topic, Achievement, ActivityItem, PostComment models + seed data
├── local_database.dart            # CirculDatabase singleton (SQLite)
├── feed_post_repository.dart      # FeedPostRepository
├── comment_repository.dart        # CommentRepository
├── saved_post_repository.dart     # SavedPostRepository
├── liked_post_repository.dart     # LikedPostRepository
└── user_repository.dart           # UserRepository

docs/
├── 00_blueprint_index.md          # Index semua dokumen
├── 01_architecture.md             # Architecture overview
├── 02_app_flow.md                 # App flow & navigation
├── 03_project_structure.md        # (dokumen ini)
├── screen_flow.md                 # Screen flow legacy (versi awal)
└── circul_blueprint_v2.md         # Blueprint lengkap multi-phase

supabase/
└── migrations/
    └── 20260607000000_create_profiles.sql  # Profiles table + RLS + functions

test/
├── widget_test.dart               # Comprehensive widget tests (50KB)
└── relative_timestamp_test.dart   # Unit test for timestamp formatting

assets/
├── images/                        # Static images (avatar, post images, welcome)
└── animations/
    └── like_button/               # Lottie animation files
```

---

## Naming Conventions

### Files

| Tipe | Konvensi | Contoh |
|---|---|---|
| Screen | `<feature>_screen.dart` | `home_screen.dart`, `profile_screen.dart` |
| Widget | `<deskripsi>.dart` (snake_case) | `feed_post_card.dart`, `chip_button.dart` |
| Model | `<entity>.dart` | `editable_profile.dart` |
| Repository | `<entity>_repository.dart` | `feed_post_repository.dart` |
| Constants | `constants.dart` | `lib/core/constants.dart` |
| Barrel file | `<folder>_widgets.dart` | `shared_widgets.dart` |

### Classes

| Tipe | Konvensi | Contoh |
|---|---|---|
| Screen widget | `<Name>Screen` | `HomeScreen`, `MapScreen` |
| State class | `_<Name>ScreenState` | `_HomeScreenState` |
| Reusable widget | `<Name>` (descriptive) | `FeedPostCard`, `ChipButton` |
| Private widget | `_<Name>` | `_HomeHeader`, `_PostImageMedia` |
| Repository | `<Entity>Repository` | `FeedPostRepository` |
| Model | `<Name>` (noun) | `FeedPost`, `EditableProfile` |
| Interface | `<Name>` (abstract class) | `AuthRepository`, `ProfileRemoteDataSource` |
| Exception | `<Name>Failure` / `<Name>Exception` | `AuthFailure` |

### Constants

| Tipe | Konvensi | Contoh |
|---|---|---|
| Color | `k<Name>` (lowerCamelCase) | `kCirculGreen`, `kInk`, `kMuted` |
| Asset path | `<name>Asset` | `avatarAsset`, `zeroWasteAsset` |
| Config | `UPPER_SNAKE_CASE` via `--dart-define` | `SUPABASE_URL`, `OSM_TILE_URL_TEMPLATE` |

---

## Import Conventions

### Urutan Import (mengikuti Dart style guide)

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';

// 4. Project imports (relative)
import '../core/constants.dart';
import '../mock_data.dart';
import '../shared/sarah_avatar.dart';
```

### Re-export Pattern

`mock_data.dart` re-exports `core/constants.dart`:

```dart
// lib/mock_data.dart
export 'core/constants.dart';
```

Ini artinya `import '../mock_data.dart'` juga memberikan akses ke semua warna di `constants.dart`. Pattern ini dipertahankan untuk backward compatibility.

---

## File Size Guidelines

| Kategori | Max Baris | Status Saat Ini |
|---|---|---|
| Screen file | ~500 | ❌ 3 file melebihi: map (2756), welcome (2512), search (1313) |
| Widget file | ~300 | ✅ Semua di bawah batas |
| Repository file | ~200 | ✅ Semua di bawah batas |
| Model file | ~100 | ✅ Semua di bawah batas |
| Test file | ~1000 | ❌ `widget_test.dart` 50KB (tapi ini oke untuk test) |

**Rekomendasi**: File di atas 500 baris harus direncanakan untuk dipecah. Lihat `REFACTOR_PLAN.md` untuk rencana decomposition.

---

## Folder Ownership

| Folder | Owner | Tanggung Jawab |
|---|---|---|
| `core/` | Siapapun | Token global (warna, asset paths). Tidak boleh import file project lain. |
| `shared/` | Siapapun | Widget yang dipakai ≥2 fitur. Tidak boleh mengandung business logic. |
| `auth/` | Auth team | Repository, data source, error types. Tidak boleh import UI. |
| `welcome/` | Auth team | Onboarding + auth UI screens. Hanya import dari `auth/`, `core/`, `shared/`. |
| `home/` | Feed team | Home screen + feed cards. Import `feed_post_repository`, `comment_repository`. |
| `new_post/` | Feed team | Post composer. Import `feed_post_repository`. |
| `comments/` | Feed team | Comment screen. Import `comment_repository`. |
| `map/` | Map team | Map screen + overlay widgets. Import `feed_post_repository`, `geolocator`, `flutter_map`. |
| `check_in/` | Map team | Capture result flow. Independent dari map screen logic. |
| `search/` | Discovery team | Search + fuzzy ranking. Import `feed_post_repository`. |
| `event/` | Event team | Event listing (masih placeholder). |
| `profile/` | Profile team | Profile CRUD, achievements, stats, tabs. Import `user_repository`. |
| `image_viewer/` | Siapapun | Fullscreen image preview. Standalone. |

---

## Asset Management

### Image Assets

Lokasi: `assets/images/`

| File | Dipakai Di | Deskripsi |
|---|---|---|
| `avatar_sarah.png` | SarahAvatar, default profile | Avatar default |
| `post_zero_waste.png` | Seed data post #1 | Gambar post sampel |
| `post_books.png` | Seed data post #2 | Gambar post sampel |
| `activity_cleanup.png` | Activity cards | Gambar aktivitas |
| `welcome_cleanup.png` | Welcome screen | Ilustrasi onboarding |

### Animation Assets

Lokasi: `assets/animations/like_button/`

Lottie animation untuk like button. Digunakan oleh `AnimatedLikeIcon` di `shared/`.

### Registrasi di pubspec.yaml

```yaml
flutter:
  assets:
    - assets/images/
    - assets/animations/
    - assets/animations/like_button/
```

**Aturan**: Setiap folder asset baru harus didaftarkan di `pubspec.yaml`. Lupa mendaftarkan akan menyebabkan runtime error `Unable to load asset`.
