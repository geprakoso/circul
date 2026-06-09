# 04 — Data Model & Database

> **Scope**: Semua entity, SQLite schema, Supabase schema, relationships, repository API  
> **Audience**: Backend developer, database maintainer  
> **Terakhir diupdate**: 2026-06-09

---

## Overview

Circul menggunakan **dual storage**:

| Layer | Teknologi | Digunakan Untuk |
|---|---|---|
| Local | SQLite via `sqflite` | Feed posts, comments, saved/liked posts, user profile cache |
| Remote | Supabase (PostgreSQL) | Auth, profiles, username uniqueness |

Data flow saat ini: **local-first**. Semua post, comment, save, like disimpan lokal. Hanya auth dan profile yang disinkronkan ke Supabase.

---

## Entity Relationship Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  feed_posts  │────<│ post_comments │    │    users     │
│              │     │              │     │              │
│ id (PK)      │     │ id (PK)      │     │ id (PK)      │
│ author       │     │ post_id (FK) │     │ name         │
│ title        │     │ author       │     │ username (UQ)│
│ body         │     │ body         │     │ bio          │
│ image_asset  │     │ initials     │     │ location     │
│ topic        │     │ avatar_color │     │ image_path   │
│ likes        │     │ likes        │     │ is_current   │
│ comments     │     │ location_*   │     │ sync_status  │
│ location_*   │     │ sync_status  │     │ created_at   │
│ image_paths  │     │ created_at   │     │ updated_at   │
│ sync_status  │     └──────────────┘     └──────────────┘
│ created_at   │
│ updated_at   │     ┌──────────────┐     ┌──────────────┐
└──────┬───────┘     │ saved_posts  │     │ liked_posts  │
       │             │              │     │              │
       │────────────<│ post_id (FK) │     │ post_id (FK) │>────────────│
                     │ created_at   │     │ created_at   │
                     │ updated_at   │     │ updated_at   │
                     └──────────────┘     └──────────────┘

Supabase (Remote):
┌──────────────────┐
│ profiles         │
│                  │
│ id (PK, FK→auth) │
│ name             │
│ username (UQ)    │
│ bio              │
│ location         │
│ image_path       │
│ created_at       │
│ updated_at       │
└──────────────────┘
```

---

## SQLite Schema

File: `lib/local_database.dart`  
Database: `circul.db`  
Current version: **9**

### Table: `feed_posts`

```sql
CREATE TABLE feed_posts (
  id                  TEXT PRIMARY KEY,
  author              TEXT NOT NULL,
  city                TEXT NOT NULL,
  time_ago            TEXT NOT NULL,
  title               TEXT NOT NULL,
  body                TEXT NOT NULL,
  image_asset         TEXT NOT NULL,
  image_paths         TEXT NOT NULL DEFAULT '[]',    -- JSON array of local file paths
  location_enabled    INTEGER NOT NULL DEFAULT 0,
  location_label      TEXT,
  coordinate_label    TEXT,
  location_latitude   REAL,
  location_longitude  REAL,
  checkout_completed  INTEGER NOT NULL DEFAULT 0,
  likes               INTEGER NOT NULL DEFAULT 0,
  comments            INTEGER NOT NULL DEFAULT 0,
  topic               TEXT,
  allow_replies       INTEGER NOT NULL DEFAULT 1,
  sync_status         TEXT NOT NULL DEFAULT 'local',
  created_at          INTEGER NOT NULL,              -- millisecondsSinceEpoch
  updated_at          INTEGER NOT NULL
);

CREATE INDEX idx_feed_posts_created_at ON feed_posts(created_at DESC);
```

### Table: `post_comments`

```sql
CREATE TABLE post_comments (
  id                  TEXT PRIMARY KEY,
  post_id             TEXT NOT NULL,
  author              TEXT NOT NULL,
  time_ago            TEXT NOT NULL,
  body                TEXT NOT NULL,
  initials            TEXT NOT NULL,
  avatar_color        INTEGER NOT NULL,              -- Color value as int
  location_enabled    INTEGER NOT NULL DEFAULT 0,
  location_label      TEXT,
  coordinate_label    TEXT,
  location_latitude   REAL,
  location_longitude  REAL,
  likes               INTEGER NOT NULL DEFAULT 0,
  sync_status         TEXT NOT NULL DEFAULT 'local',
  created_at          INTEGER NOT NULL,
  updated_at          INTEGER NOT NULL,
  FOREIGN KEY(post_id) REFERENCES feed_posts(id) ON DELETE CASCADE
);

CREATE INDEX idx_post_comments_post_created_at ON post_comments(post_id, created_at ASC);
```

### Table: `saved_posts`

```sql
CREATE TABLE saved_posts (
  post_id    TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY(post_id) REFERENCES feed_posts(id) ON DELETE CASCADE
);

CREATE INDEX idx_saved_posts_created_at ON saved_posts(created_at DESC);
```

### Table: `liked_posts`

```sql
CREATE TABLE liked_posts (
  post_id    TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY(post_id) REFERENCES feed_posts(id) ON DELETE CASCADE
);

CREATE INDEX idx_liked_posts_created_at ON liked_posts(created_at DESC);
```

### Table: `users`

```sql
CREATE TABLE users (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  username    TEXT NOT NULL UNIQUE,
  bio         TEXT NOT NULL,
  location    TEXT NOT NULL,
  image_path  TEXT,
  is_current  INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'local',
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_users_username ON users(username COLLATE NOCASE);
CREATE INDEX idx_users_is_current ON users(is_current);
```

### Migration History

| Version | Perubahan |
|---|---|
| 1 | Create `feed_posts` |
| 2 | Add `image_paths` column |
| 3 | Create `post_comments` |
| 4 | Add `location_enabled`, `location_label`, `coordinate_label` to feed_posts |
| 5 | Add `location_latitude`, `location_longitude` to feed_posts |
| 6 | Add `checkout_completed` to feed_posts, location columns to post_comments |
| 7 | Create `saved_posts` |
| 8 | Create `liked_posts` |
| 9 | Create `users` |

**Aturan migration**: Selalu increment version di `openDatabase(version: N)` dan tambahkan `if (oldVersion < N)` block di `_upgrade`. Jangan pernah modifikasi migration yang sudah dirilis.

---

## Supabase Schema

File: `supabase/migrations/20260607000000_create_profiles.sql`

### Table: `profiles`

```sql
CREATE TABLE public.profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  username   TEXT NOT NULL UNIQUE,
  bio        TEXT NOT NULL DEFAULT '',
  location   TEXT NOT NULL DEFAULT '',
  image_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX profiles_username_lower_idx ON public.profiles (lower(username));
```

### Row Level Security (RLS)

| Policy | Operation | Rule |
|---|---|---|
| Authenticated users can read profiles | SELECT | Semua authenticated user bisa baca semua profile |
| Users can create their own profile | INSERT | Hanya bisa insert row dengan `id = auth.uid()` |
| Users can update their own profile | UPDATE | Hanya bisa update row milik sendiri |

### Database Functions

| Function | Input | Output | Deskripsi |
|---|---|---|---|
| `is_email_taken(check_email)` | TEXT | BOOLEAN | Cek apakah email sudah terdaftar di `auth.users` (case-insensitive) |
| `is_username_taken(check_username)` | TEXT | BOOLEAN | Cek apakah username sudah dipakai di `profiles` (case-insensitive, strip @) |

### Trigger

```sql
-- Auto-create profile saat user baru register
CREATE TRIGGER on_auth_user_created_create_profile
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();
```

Trigger mengambil `name` dan `username` dari `raw_user_meta_data` yang dikirim saat signup. Fallback: name → `'Circul User'`, username → `'user_' + id[:8]`.

---

## Dart Entity Classes

### FeedPost (`lib/mock_data.dart`)

```dart
class FeedPost {
  final String id;
  final String author;
  final String city;
  final String timeAgo;
  final String title;
  final String body;
  final String imageAsset;          // Asset path (bundled images)
  final DateTime? createdAt;
  final String topic;
  final List<String> imagePaths;    // Local file paths (user uploads)
  final bool locationEnabled;
  final String? locationLabel;
  final String? coordinateLabel;
  final double? locationLatitude;
  final double? locationLongitude;
  final bool checkoutCompleted;
  final int likes;
  final int comments;

  LatLng? get locationPoint;        // Computed from lat/lng or coordinateLabel
  FeedPost copyWith({...});
}
```

### PostComment (`lib/mock_data.dart`)

```dart
class PostComment {
  final String id;
  final String postId;
  final String author;
  final String timeAgo;
  final String body;
  final String initials;
  final Color avatarColor;
  final int likes;
  final bool locationEnabled;
  final String? locationLabel;
  final String? coordinateLabel;
  final double? locationLatitude;
  final double? locationLongitude;
}
```

### EditableProfile (`lib/profile/editable_profile.dart`)

```dart
class EditableProfile {
  final String name;
  final String username;
  final String bio;
  final String location;
  final String? imagePath;

  EditableProfile copyWith({...});
  // Implements == and hashCode
}
```

### Topic (`lib/mock_data.dart`)

```dart
class Topic {
  final String icon;    // Emoji
  final String title;
  final String count;   // e.g. "12.4K post"
}
```

### Achievement (`lib/mock_data.dart`)

```dart
class Achievement {
  final IconData icon;
  final String title;
  final String caption;
}
```

### ActivityItem (`lib/mock_data.dart`)

```dart
class ActivityItem {
  final String category;
  final String title;
  final String distance;
  final String time;
  final IconData icon;
}
```

---

## Repository API

### FeedPostRepository (`lib/feed_post_repository.dart`)

| Method | Return | Deskripsi |
|---|---|---|
| `getPosts()` | `Future<List<FeedPost>>` | Ambil semua posts, ordered by `created_at DESC`. Seed data di-insert jika tabel kosong. |
| `addPost(FeedPost)` | `Future<void>` | Insert post baru. `id` di-generate dari `DateTime.now().microsecondsSinceEpoch`. |
| `updatePost(FeedPost)` | `Future<void>` | Update post existing by `id`. |
| `completeCheckout(String id)` | `Future<void>` | Set `checkout_completed = 1` pada post. |

### CommentRepository (`lib/comment_repository.dart`)

| Method | Return | Deskripsi |
|---|---|---|
| `getComments(String postId)` | `Future<List<PostComment>>` | Ambil comments untuk post. Seed data di-insert jika tabel kosong. |
| `addComment(PostComment)` | `Future<void>` | Insert comment + increment `comments` count pada `feed_posts`. |
| `addCheckoutComment({required FeedPost post})` | `Future<void>` | Insert system comment "Check-out berhasil" oleh post author. |

### SavedPostRepository (`lib/saved_post_repository.dart`)

| Method | Return | Deskripsi |
|---|---|---|
| `isSaved(String postId)` | `Future<bool>` | Cek apakah post tersimpan. |
| `toggleSave(String postId)` | `Future<bool>` | Toggle saved state, return `true` jika sekarang saved. |
| `getSavedPostIds()` | `Future<Set<String>>` | Ambil semua post ID yang tersimpan. |

### LikedPostRepository (`lib/liked_post_repository.dart`)

| Method | Return | Deskripsi |
|---|---|---|
| `isLiked(String postId)` | `Future<bool>` | Cek apakah post di-like. |
| `toggleLike(String postId)` | `Future<bool>` | Toggle like state, return `true` jika sekarang liked. Update `likes` count di `feed_posts`. |
| `getLikedPostIds()` | `Future<Set<String>>` | Ambil semua post ID yang di-like. |

### UserRepository (`lib/user_repository.dart`)

| Method | Return | Deskripsi |
|---|---|---|
| `getCurrentUserProfile()` | `Future<EditableProfile>` | Ambil profil user aktif. Priority: Supabase → SQLite → default. |
| `saveCurrentUserProfile(EditableProfile)` | `Future<void>` | Simpan profil. Jika ada remote, push ke Supabase dulu. |
| `getTakenUsernames({excludingUserId})` | `Future<Set<String>>` | Ambil semua username yang sudah dipakai (untuk validasi uniqueness). |

### AuthRepository (`lib/auth/auth_repository.dart`)

| Method | Return | Deskripsi |
|---|---|---|
| `hasActiveSession` | `bool` (getter) | Apakah ada session Supabase aktif |
| `signUpWithEmail({...})` | `Future<EditableProfile>` | Register + create profile |
| `signInWithEmail({...})` | `Future<EditableProfile>` | Login + fetch profile |
| `verifyEmailOtp({email, token})` | `Future<void>` | Verifikasi kode OTP 8 digit |
| `resendEmailVerification(email)` | `Future<void>` | Kirim ulang email verifikasi |
| `isEmailTaken(email)` | `Future<bool>` | Cek via Supabase RPC function |
| `isUsernameTaken(username)` | `Future<bool>` | Cek via Supabase RPC function |
| `signOut()` | `Future<void>` | Logout dari Supabase |

---

## Seed Data

Aplikasi menyediakan seed data di `lib/mock_data.dart` yang digunakan sebagai fallback saat database kosong:

| Constant | Tipe | Isi |
|---|---|---|
| `feedPosts` | `List<FeedPost>` | 2 post sampel (Zero Waste, Buku Lingkungan) |
| `postComments` | `List<PostComment>` | 2 komentar sampel |
| `topics` | `List<Topic>` | 10 topik lingkungan |
| `achievements` | `List<Achievement>` | 4 badges (Eco Starter, Zero Waste Warrior, Green Contributor, Community Builder) |
| `nearbyActivities` | `List<ActivityItem>` | 3 aktivitas event sampel |

Seed data di-insert ke SQLite saat repository pertama kali dipanggil dan tabel masih kosong.

---

## Sync Status Column

Semua tabel SQLite punya column `sync_status TEXT NOT NULL DEFAULT 'local'`.

| Value | Arti |
|---|---|
| `local` | Data hanya ada di device |
| `syncing` | Sedang di-upload (belum diimplementasi) |
| `synced` | Sudah tersinkronkan ke server (belum diimplementasi) |

**Status saat ini**: Column ada di schema tapi **belum ada sync logic**. Ini disiapkan untuk future remote sync.
