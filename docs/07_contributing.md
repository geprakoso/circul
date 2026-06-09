# 07 — Contributing & Conventions

> **Scope**: Coding standards, how to add features, PR checklist, testing, environment setup  
> **Audience**: Semua developer (terutama developer baru)  
> **Terakhir diupdate**: 2026-06-09

---

## Development Setup

### Prerequisites

| Tool | Versi Minimum | Cek |
|---|---|---|
| Flutter SDK | 3.x stable | `flutter --version` |
| Dart SDK | 3.x (bundled with Flutter) | `dart --version` |
| Xcode | 15+ (untuk iOS/macOS) | `xcode-select --version` |
| Android Studio | 2024+ (untuk Android) | - |
| Supabase CLI (optional) | latest | `npx supabase --version` |

### First-Time Setup

```bash
# 1. Clone repository
git clone https://github.com/geprakoso/circul.git
cd circul

# 2. Install dependencies
flutter pub get

# 3. Run the app (dengan default Supabase)
flutter run

# 4. Atau run dengan custom Supabase
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### Environment Variables

| Variable | Default | Deskripsi |
|---|---|---|
| `SUPABASE_URL` | (lihat `main.dart`) | Supabase project URL |
| `SUPABASE_ANON_KEY` | (lihat `main.dart`) | Supabase anon public key |
| `MAP_TILE_URL_TEMPLATE` | Geoapify URL | Map tile server URL template |
| `OSM_TILE_URL_TEMPLATE` | - | Legacy alias for map tiles |
| `APP_USER_AGENT_PACKAGE_NAME` | `com.example.circul` | User agent for API calls |

---

## Coding Standards

### Dart Style

Ikuti [Effective Dart](https://dart.dev/guides/language/effective-dart) + aturan tambahan berikut:

### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  // 1. Constructor (const jika memungkinkan)
  const MyWidget({super.key, required this.title});

  // 2. Final fields (sorted: required first, then optional)
  final String title;
  final VoidCallback? onTap;

  // 3. build method
  @override
  Widget build(BuildContext context) {
    return ...;
  }
}
```

### StatefulWidget Structure

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // 1. Constants (static const)
  static const _animationDuration = Duration(milliseconds: 300);

  // 2. Controllers & mutable state
  final _controller = TextEditingController();
  var _isLoading = false;

  // 3. Lifecycle methods (initState, dispose, didUpdateWidget)
  @override
  void initState() { ... }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 4. build method
  @override
  Widget build(BuildContext context) { ... }

  // 5. Private helper methods (grouped by purpose)
  void _handleSubmit() { ... }
  Future<void> _loadData() async { ... }
}
```

### Naming

| Pattern | Contoh | Kapan Pakai |
|---|---|---|
| `const` constructor | `const MyWidget()` | Selalu jika memungkinkan |
| Private underscore | `_PrivateWidget`, `_loadData()` | Widget/method yang hanya dipakai internal |
| `k` prefix | `kCirculGreen` | Top-level constants (warna, sizing) |
| `is/has` prefix | `isLoading`, `hasError` | Boolean variables |
| `on` prefix | `onTap`, `onPostCreated` | Callback parameters |
| `handle/do` prefix | `_handleSubmit()`, `_doRefresh()` | Internal event handlers |

### Import Order

```dart
// 1. dart:
import 'dart:async';

// 2. package:flutter
import 'package:flutter/material.dart';

// 3. package:third_party
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Relative project imports
import '../core/constants.dart';
```

### Const Usage

- **Selalu** gunakan `const` untuk widget yang tidak berubah
- **Selalu** gunakan `const` constructor kalau memungkinkan
- **Selalu** gunakan `const` untuk `EdgeInsets`, `TextStyle`, `Duration`, `Color` literals

---

## How to Add a New Feature

### Template Folder Structure

```
lib/
└── <feature_name>/
    ├── <feature_name>_screen.dart    # Main screen
    └── widgets/
        ├── <widget_a>.dart
        └── <widget_b>.dart
```

### Checklist Menambah Feature

- [ ] Buat folder `lib/<feature_name>/`
- [ ] Buat screen utama `<feature_name>_screen.dart`
- [ ] Jika butuh data persistence:
  - [ ] Tambah tabel di `lib/local_database.dart` (increment version)
  - [ ] Buat `<feature_name>_repository.dart`
- [ ] Jika butuh Supabase:
  - [ ] Buat migration file di `supabase/migrations/`
  - [ ] Tambah RLS policies
- [ ] Jika perlu route ke tab baru:
  - [ ] Tambah branch di `CirculShell` (`main.dart`)
  - [ ] Tambah icon di `CirculBottomNav`
- [ ] Jika perlu route fullscreen:
  - [ ] Tambah `Navigator.push` dari screen pemanggil
- [ ] Tambah screen ke dokumentasi:
  - [ ] Update `docs/02_app_flow.md`
  - [ ] Update `docs/03_project_structure.md`
  - [ ] Update `docs/05_feature_guide.md`
- [ ] Tulis test di `test/`
- [ ] Run `flutter analyze` — 0 errors

### Contoh: Menambah Feature "Notifications"

```
1. Buat lib/notifications/
   ├── notification_screen.dart
   └── widgets/
       ├── notification_card.dart
       └── notification_filter.dart

2. Tambah tabel di local_database.dart:
   if (oldVersion < 10) {
     await db.execute('''
       CREATE TABLE notifications (
         id TEXT PRIMARY KEY,
         type TEXT NOT NULL,
         title TEXT NOT NULL,
         body TEXT NOT NULL,
         read INTEGER NOT NULL DEFAULT 0,
         created_at INTEGER NOT NULL
       )
     ''');
   }
   // Update version: openDatabase(version: 10)

3. Buat notification_repository.dart

4. Tambah route di main.dart:
   // Bisa sebagai fullscreen push dari home
   Navigator.push(context, MaterialPageRoute(
     builder: (context) => const NotificationScreen(),
   ));

5. Update docs
6. Write tests
7. flutter analyze
```

---

## How to Add a New Database Table

### Langkah

1. **Buka** `lib/local_database.dart`
2. **Increment** version number di `openDatabase`
3. **Tambah** migration block di `_upgrade`:

```dart
Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
  // ... existing migrations ...
  
  if (oldVersion < NEW_VERSION) {
    await db.execute('''
      CREATE TABLE your_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    // Optional: create indexes
    await db.execute('''
      CREATE INDEX idx_your_table_created_at ON your_table(created_at DESC)
    ''');
  }
}
```

### Rules

| Rule | Alasan |
|---|---|
| JANGAN modifikasi migration yang sudah dirilis | User yang sudah install versi lama akan skip migration itu |
| Selalu tambah migration baru sebagai `if (oldVersion < N)` | Incremental upgrade support |
| Gunakan `TEXT` untuk ID, bukan `INTEGER` | Consistency + UUID-ready |
| Selalu tambah `created_at` dan `updated_at` | Audit trail |
| Selalu tambah `sync_status TEXT DEFAULT 'local'` | Future sync support |
| Test: uninstall app → install ulang → pastikan fresh DB works | Verify onCreate + onUpgrade paths |

---

## How to Add a Supabase Table

### Langkah

1. **Buat** migration file: `supabase/migrations/YYYYMMDDHHMMSS_description.sql`
2. **Tulis** SQL:

```sql
-- Create table
CREATE TABLE public.your_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.your_table ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can read own data"
  ON public.your_table FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own data"
  ON public.your_table FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own data"
  ON public.your_table FOR UPDATE
  USING (auth.uid() = user_id);
```

3. **Apply** migration:

```bash
npx supabase db push
```

### Rules

| Rule | Alasan |
|---|---|
| Selalu enable RLS | Security — tanpa RLS, semua data public |
| Selalu buat policies | RLS tanpa policy = block all access |
| Reference `auth.users(id)` untuk user-owned data | Cascade delete saat user dihapus |
| Gunakan `TIMESTAMPTZ` untuk timestamps | Timezone-aware |
| Test policies di Supabase SQL editor | Verify access sebelum deploy |

---

## Testing

### Running Tests

```bash
# All tests
flutter test

# Single test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

### Test Files

| File | Baris | Coverage |
|---|---|---|
| `test/widget_test.dart` | ~1500+ | Comprehensive widget tests |
| `test/relative_timestamp_test.dart` | ~50 | Unit test for timestamp formatting |

### Writing Tests

```dart
testWidgets('should display feed posts', (tester) async {
  // Arrange
  final repository = FeedPostRepository();
  
  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(feedPostRepository: repository),
    ),
  );
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.byType(FeedPostCard), findsWidgets);
});
```

### Test Conventions

| Konvensi | Contoh |
|---|---|
| Nama test deskriptif | `'should display error when email is taken'` |
| Arrange-Act-Assert pattern | Setup → Execute → Verify |
| Gunakan repository parameter injection | `HomeScreen(feedPostRepository: mockRepo)` |
| Test loading, success, dan error states | 3 test per async operation |

---

## PR Checklist

Sebelum submit Pull Request:

### Code Quality

- [ ] `flutter analyze` = 0 errors, 0 warnings
- [ ] `flutter test` = semua pass
- [ ] Tidak ada `print()` statements (gunakan `debugPrint()` kalau perlu)
- [ ] Tidak ada hardcoded strings untuk teks user-facing (kecuali masih MVP)
- [ ] `const` dipakai dimana memungkinkan
- [ ] Controllers di-dispose di `dispose()`

### Architecture

- [ ] Widgets tidak import repositories langsung (lewat callback/parameter)
- [ ] Tidak ada circular imports
- [ ] File baru ≤500 baris
- [ ] Folder structure mengikuti konvensi (`docs/03_project_structure.md`)

### Documentation

- [ ] Update docs jika ada perubahan structure/flow/data model
- [ ] Comments untuk logic yang tidak obvious
- [ ] TODO comments pakai format `// TODO(username): description`

### Testing

- [ ] Test untuk happy path
- [ ] Test untuk error states
- [ ] Test untuk edge cases (empty data, null values)

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---|---|
| `Unable to load asset` | Cek path di `pubspec.yaml` → `flutter: assets:` |
| `MissingPluginException` | `flutter clean && flutter pub get` |
| `Supabase init failed` | Cek internet + SUPABASE_URL + SUPABASE_ANON_KEY |
| `Database version mismatch` | Increment version di `openDatabase` |
| `RLS violation` | Cek policies di Supabase dashboard |
| Map tiles tidak muncul | Cek Geoapify API key validity + internet |
| Location permission denied | Cek platform permission settings + `geolocator` config |

### Reset Local Database

```dart
// Hapus database dan mulai dari awal
await deleteDatabase('circul.db');
// Restart app
```

Atau uninstall + install ulang app.

### Debug Supabase Queries

```bash
# Lihat Supabase logs
npx supabase functions logs

# Query langsung di SQL Editor (Supabase Dashboard)
SELECT * FROM profiles WHERE id = 'user-uuid-here';
```
