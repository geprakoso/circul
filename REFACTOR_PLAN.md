# Rencana Refactoring: Struktur Folder Flutter — Circul

> **Tujuan**: Memecah `screens.dart` (2363 baris, 73 KB) dan `widgets.dart` (653 baris)
> menjadi file-file terpisah per fitur/screen, serta mengisi folder-folder yang sudah ada
> namun masih kosong. Tidak ada perubahan logika — hanya **memindahkan kode**.

---

## Gambaran Struktur Akhir

```
lib/
├── main.dart                          ← MODIFIKASI (hapus import screens.dart & widgets.dart lama)
├── mock_data.dart                     ← TIDAK DIUBAH
├── feed_post_repository.dart          ← TIDAK DIUBAH
├── local_database.dart                ← TIDAK DIUBAH
│
├── core/                              ← BARU — konstanta warna, tema, token global
│   └── constants.dart                 ← kCirculGreen, kLine, kInk, kMuted, kSoftGreen (dari mock_data.dart)
│
├── shared/                            ← BARU — widgets yang dipakai ≥2 fitur berbeda
│   ├── circul_header.dart             ← CirculHeader, CirculLogo, _CirculLogoPainter
│   ├── sarah_avatar.dart              ← SarahAvatar
│   ├── search_field_shell.dart        ← SearchFieldShell
│   ├── chip_button.dart               ← ChipButton
│   ├── section_title.dart             ← SectionTitle
│   ├── notification_icon.dart         ← NotificationIcon
│   └── shared_widgets.dart            ← barrel file: export semua shared widgets
│
├── home/
│   ├── home_screen.dart               ← HomeScreen, _HomeScreenState, _HomeHeader, _HomeComposerEntry
│   └── widgets/
│       └── feed_post_card.dart        ← FeedPostCard, _PostImageMedia, _LocalPostImage, _Pill, _Dot, _ActionButton
│
├── new_post/                          ← BARU (saat ini ada di screens.dart, belum punya folder)
│   ├── new_post_screen.dart           ← NewPostScreen, _NewPostScreenState
│   └── widgets/
│       ├── compose_header.dart        ← _ComposeHeader
│       ├── compose_footer.dart        ← _ComposeFooter, _ReplyToggle
│       ├── compose_tools.dart         ← _ComposeTools, _ComposeToolButton
│       ├── topic_autocomplete.dart    ← _TopicAutocomplete, _TopicAutocompleteState
│       └── attachment_media_strip.dart← _AttachmentMediaStrip, _ImagePreviewCard,
│                                         _LocationPlaceholderBox, _MapPinPlaceholder,
│                                         _MiniMapPlaceholderPainter
│
├── image_viewer/                      ← BARU (dipakai dari home & new_post)
│   └── uploaded_image_fullscreen_page.dart ← UploadedImageFullscreenPage
│
├── map/                               ← SUDAH ADA (kosong) — isi sekarang
│   ├── map_screen.dart                ← MapScreen, _MapScreenState
│   └── widgets/
│       ├── waste_map_painter.dart     ← WasteMapPainter
│       ├── impact_legend.dart         ← ImpactLegend
│       ├── map_square_button.dart     ← MapSquareButton
│       ├── map_marker.dart            ← MapMarker
│       ├── location_bubble.dart       ← LocationBubble, UserLocationPulse
│       └── activity_sheet.dart        ← ActivitySheet, ActivityCard
│
├── search/                            ← SUDAH ADA (kosong) — isi sekarang
│   ├── search_screen.dart             ← SearchScreen, _SearchScreenState
│   └── widgets/
│       └── topic_row.dart             ← TopicRow
│
├── event/                             ← SUDAH ADA (kosong) — isi sekarang
│   └── event_screen.dart              ← EventScreen, _EventScreenState
│
└── profile/                           ← SUDAH ADA (kosong) — isi sekarang
    ├── profile_screen.dart            ← ProfileScreen, _ProfileScreenState
    └── widgets/
        ├── profile_meta.dart          ← ProfileMeta
        ├── profile_stats.dart         ← ProfileStats
        ├── achievement_badge.dart     ← AchievementBadge
        ├── segmented_profile_tabs.dart← SegmentedProfileTabs
        └── profile_placeholder.dart  ← ProfilePlaceholder
```

---

## Langkah Eksekusi (Berurutan)

### LANGKAH 1 — Buat `lib/core/constants.dart`

Pindahkan konstanta warna yang saat ini ada di `mock_data.dart` ke file baru ini.
File ini tidak boleh import apapun selain `package:flutter/material.dart`.

**Konten yang dipindah dari `mock_data.dart`:**
```dart
import 'package:flutter/material.dart';

const kCirculGreen = Color(0xFF34C77B);
const kSoftGreen   = Color(0xFFE9FFF0);
const kLine        = Color(0xFFE5E7EB);
const kInk         = Color(0xFF111827);
const kMuted       = Color(0xFF6B7280);
```

> ⚠️ Setelah memindahkan konstanta, tambahkan di `mock_data.dart`:
> `export 'core/constants.dart';`
> agar tidak perlu ubah semua import yang sudah ada ke `mock_data.dart`.

---

### LANGKAH 2 — Buat file-file `shared/`

Buat folder `lib/shared/` dan buat tiap file berikut:

#### `lib/shared/notification_icon.dart`
Pindahkan class `NotificationIcon` dari `widgets.dart`.
Import: `package:flutter/material.dart`, `../core/constants.dart`

#### `lib/shared/circul_header.dart`
Pindahkan class `CirculHeader`, `CirculLogo`, `_CirculLogoPainter` dari `widgets.dart`.
Import: `package:flutter/material.dart`, `../core/constants.dart`, `./notification_icon.dart`

#### `lib/shared/sarah_avatar.dart`
Pindahkan class `SarahAvatar` dari `widgets.dart`.
Import: `package:flutter/material.dart`, `../core/constants.dart`, `../mock_data.dart`

#### `lib/shared/search_field_shell.dart`
Pindahkan class `SearchFieldShell` dari `widgets.dart`.
Import: `package:flutter/material.dart`, `../core/constants.dart`

#### `lib/shared/chip_button.dart`
Pindahkan class `ChipButton` dari `widgets.dart`.
Import: `package:flutter/material.dart`, `../core/constants.dart`

#### `lib/shared/section_title.dart`
Pindahkan class `SectionTitle` dari `widgets.dart`.
Import: `package:flutter/material.dart`, `../core/constants.dart`

#### `lib/shared/shared_widgets.dart` (barrel file)
```dart
export 'circul_header.dart';
export 'sarah_avatar.dart';
export 'search_field_shell.dart';
export 'chip_button.dart';
export 'section_title.dart';
export 'notification_icon.dart';
```

---

### LANGKAH 3 — Buat `lib/image_viewer/uploaded_image_fullscreen_page.dart`

Pindahkan class `UploadedImageFullscreenPage` dari `widgets.dart`.
Import: `dart:io`, `package:flutter/material.dart`, `../core/constants.dart`

---

### LANGKAH 4 — Buat file-file `home/`

#### `lib/home/widgets/feed_post_card.dart`
Pindahkan class-class berikut dari `widgets.dart`:
- `FeedPostCard`
- `_PostImageMedia`
- `_LocalPostImage`
- `_Pill`
- `_Dot`
- `_ActionButton`

Import:
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../mock_data.dart';
import '../../core/constants.dart';
import '../../image_viewer/uploaded_image_fullscreen_page.dart';
import '../shared/sarah_avatar.dart';
```

#### `lib/home/home_screen.dart`
Pindahkan class-class berikut dari `screens.dart`:
- `HomeScreen`
- `_HomeScreenState`
- `_HomeHeader`
- `_HomeComposerEntry`

Import:
```dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../mock_data.dart';
import '../feed_post_repository.dart';
import '../shared/shared_widgets.dart';
import 'widgets/feed_post_card.dart';
import '../new_post/new_post_screen.dart';
```

---

### LANGKAH 5 — Buat file-file `new_post/`

Buat folder `lib/new_post/` dan `lib/new_post/widgets/`.

#### `lib/new_post/widgets/compose_header.dart`
Pindahkan class `_ComposeHeader` dari `screens.dart`.
Ubah nama class menjadi `ComposeHeader` (hilangkan underscore karena pindah file).
Import: `package:flutter/material.dart`

#### `lib/new_post/widgets/topic_autocomplete.dart`
Pindahkan class `_TopicAutocomplete` dan `_TopicAutocompleteState`.
Ubah nama menjadi `TopicAutocomplete` dan `TopicAutocompleteState`.
Import: `package:flutter/material.dart`, `../../mock_data.dart`, `../../core/constants.dart`

#### `lib/new_post/widgets/compose_tools.dart`
Pindahkan class `_ComposeTools` dan `_ComposeToolButton`.
Ubah nama menjadi `ComposeTools` dan `ComposeToolButton`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/new_post/widgets/attachment_media_strip.dart`
Pindahkan class-class berikut:
- `_AttachmentMediaStrip` → `AttachmentMediaStrip`
- `_ImagePreviewCard` → `ImagePreviewCard`
- `_LocationPlaceholderBox` → `LocationPlaceholderBox`
- `_MapPinPlaceholder` → `MapPinPlaceholder`
- `_MiniMapPlaceholderPainter` → `MiniMapPlaceholderPainter`

Import: `dart:io`, `dart:math as math`, `package:flutter/material.dart`,
`../../core/constants.dart`, `../../image_viewer/uploaded_image_fullscreen_page.dart`

#### `lib/new_post/widgets/compose_footer.dart`
Pindahkan class `_ComposeFooter` dan `_ReplyToggle`.
Ubah nama menjadi `ComposeFooter` dan `ReplyToggle`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/new_post/new_post_screen.dart`
Pindahkan class `NewPostScreen` dan `_NewPostScreenState` dari `screens.dart`.

> ⚠️ **PENTING**: Di `_TopicAutocompleteState` ada referensi ke
> `_NewPostScreenState._softText` dan `_NewPostScreenState._background`.
> Setelah pemisahan file, ubah referensi ini menjadi konstanta lokal di
> `topic_autocomplete.dart`:
> ```dart
> static const _softText = Color(0xFF8C8F93);
> ```
> Dan ubah `_background` di `new_post_screen.dart` menjadi `static const` yang bisa
> diakses, atau duplikat nilai warnanya di `topic_autocomplete.dart` secara lokal.

Import untuk `new_post_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../feed_post_repository.dart';
import '../shared/sarah_avatar.dart';
import 'widgets/compose_header.dart';
import 'widgets/compose_footer.dart';
import 'widgets/compose_tools.dart';
import 'widgets/topic_autocomplete.dart';
import 'widgets/attachment_media_strip.dart';
```

---

### LANGKAH 6 — Isi folder `lib/map/`

#### `lib/map/widgets/waste_map_painter.dart`
Pindahkan class `WasteMapPainter` dari `screens.dart`.
Import: `dart:math as math`, `package:flutter/material.dart`

#### `lib/map/widgets/impact_legend.dart`
Pindahkan class `ImpactLegend`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/map/widgets/map_square_button.dart`
Pindahkan class `MapSquareButton`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/map/widgets/map_marker.dart`
Pindahkan class `MapMarker`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/map/widgets/location_bubble.dart`
Pindahkan class `LocationBubble` dan `UserLocationPulse`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/map/widgets/activity_sheet.dart`
Pindahkan class `ActivitySheet` dan `ActivityCard`.
Import: `package:flutter/material.dart`, `../../mock_data.dart`, `../../core/constants.dart`,
`../../shared/chip_button.dart`

#### `lib/map/map_screen.dart`
Pindahkan class `MapScreen` dan `_MapScreenState`.
Import:
```dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../shared/circul_header.dart';
import 'widgets/waste_map_painter.dart';
import 'widgets/impact_legend.dart';
import 'widgets/map_square_button.dart';
import 'widgets/map_marker.dart';
import 'widgets/location_bubble.dart';
import 'widgets/activity_sheet.dart';
```

---

### LANGKAH 7 — Isi folder `lib/search/`

#### `lib/search/widgets/topic_row.dart`
Pindahkan class `TopicRow` dari `screens.dart`.
Import: `package:flutter/material.dart`, `../../mock_data.dart`, `../../core/constants.dart`

#### `lib/search/search_screen.dart`
Pindahkan class `SearchScreen` dan `_SearchScreenState`.
Import:
```dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../mock_data.dart';
import '../shared/search_field_shell.dart';
import 'widgets/topic_row.dart';
```

---

### LANGKAH 8 — Isi folder `lib/event/`

#### `lib/event/event_screen.dart`
Pindahkan class `EventScreen` dan `_EventScreenState` dari `screens.dart`.
`ActivityCard` sudah ada di `lib/map/widgets/activity_sheet.dart`, cukup import dari sana.
Import:
```dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../mock_data.dart';
import '../shared/search_field_shell.dart';
import '../shared/chip_button.dart';
import '../shared/notification_icon.dart';
import '../map/widgets/activity_sheet.dart';
```

---

### LANGKAH 9 — Isi folder `lib/profile/`

#### `lib/profile/widgets/profile_meta.dart`
Pindahkan class `ProfileMeta`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/profile/widgets/profile_stats.dart`
Pindahkan class `ProfileStats`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/profile/widgets/achievement_badge.dart`
Pindahkan class `AchievementBadge`.
Import: `package:flutter/material.dart`, `../../mock_data.dart`, `../../core/constants.dart`

#### `lib/profile/widgets/segmented_profile_tabs.dart`
Pindahkan class `SegmentedProfileTabs`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/profile/widgets/profile_placeholder.dart`
Pindahkan class `ProfilePlaceholder`.
Import: `package:flutter/material.dart`, `../../core/constants.dart`

#### `lib/profile/profile_screen.dart`
Pindahkan class `ProfileScreen` dan `_ProfileScreenState`.
Import:
```dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../mock_data.dart';
import '../shared/shared_widgets.dart';
import '../home/widgets/feed_post_card.dart';
import 'widgets/profile_meta.dart';
import 'widgets/profile_stats.dart';
import 'widgets/achievement_badge.dart';
import 'widgets/segmented_profile_tabs.dart';
import 'widgets/profile_placeholder.dart';
```

---

### LANGKAH 10 — Update `lib/main.dart`

Ganti import lama:
```dart
// HAPUS ini:
import 'screens.dart';
import 'widgets.dart';

// GANTI dengan:
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'search/search_screen.dart';
import 'event/event_screen.dart';
import 'profile/profile_screen.dart';
import 'core/constants.dart';
import 'shared/sarah_avatar.dart';
```

---

### LANGKAH 11 — Hapus file lama

Setelah semua kode berhasil dipindahkan dan app dapat dikompilasi:

1. **Hapus** `lib/screens.dart`
2. **Hapus** `lib/widgets.dart`

> ✅ Pastikan `flutter analyze` tidak ada error sebelum menghapus file lama.

---

## Catatan Penting untuk Agent

### Perubahan Nama Class (Private → Public)
Saat memindahkan class dengan prefix `_` (private) ke file terpisah, **hilangkan underscore**
karena private class di Dart hanya berlaku dalam satu file library.

| Nama Lama (di screens.dart) | Nama Baru (di file terpisah) |
|---|---|
| `_ComposeHeader` | `ComposeHeader` |
| `_ComposeFooter` | `ComposeFooter` |
| `_ReplyToggle` | `ReplyToggle` |
| `_ComposeTools` | `ComposeTools` |
| `_ComposeToolButton` | `ComposeToolButton` |
| `_TopicAutocomplete` | `TopicAutocomplete` |
| `_AttachmentMediaStrip` | `AttachmentMediaStrip` |
| `_ImagePreviewCard` | `ImagePreviewCard` |
| `_LocationPlaceholderBox` | `LocationPlaceholderBox` |
| `_MapPinPlaceholder` | `MapPinPlaceholder` |
| `_MiniMapPlaceholderPainter` | `MiniMapPlaceholderPainter` |

Class dengan underscore yang **tetap private** (tidak perlu rename) karena dipakai hanya
di dalam satu file yang sama setelah dipisah:
- `_HomeHeader`, `_HomeComposerEntry` (tetap di `home_screen.dart`)
- `_NewPostScreenState` internal fields
- `_MapScreenState` (tetap di `map_screen.dart`)

### Dependency Kritis: `_TopicAutocomplete` → `_NewPostScreenState`
Di `screens.dart` baris ~507-508, ada referensi:
```dart
color: _NewPostScreenState._softText,
```
Ini harus diubah karena `TopicAutocomplete` akan berada di file terpisah.
**Solusi**: Definisikan `static const _softText = Color(0xFF8C8F93)` langsung
di `TopicAutocomplete` atau di `topic_autocomplete.dart` sebagai top-level constant.

### Urutan Kompilasi
Selalu buat file dependency terlebih dahulu sebelum file yang membutuhkannya:
`core/` → `shared/` → `image_viewer/` → `home/`, `map/`, `search/`, `event/`, `profile/` → `main.dart`

### Verifikasi Akhir
Jalankan perintah berikut untuk memverifikasi tidak ada error:
```bash
flutter analyze
flutter build apk --debug
```
atau minimal:
```bash
flutter pub get && flutter analyze
```
