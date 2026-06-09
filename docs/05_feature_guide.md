# 05 — Feature Guide

> **Scope**: Per-feature documentation, responsibilities, dependencies, key classes  
> **Audience**: Developer yang mau menambah/maintain fitur tertentu  
> **Terakhir diupdate**: 2026-06-09

---

## Feature Map

```
┌────────────────────────────────────────────────────────────────┐
│                         CIRCUL APP                              │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Welcome  │  │ Home     │  │ Map      │  │ Search   │       │
│  │ /Auth    │  │ /Feed    │  │ /CheckIn │  │          │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Profile  │  │ Events   │  │ Comments │  │ NewPost  │       │
│  │          │  │(skeleton)│  │          │  │          │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ SHARED: Widgets, Constants, Database, Repositories  │       │
│  └─────────────────────────────────────────────────────┘       │
└────────────────────────────────────────────────────────────────┘
```

---

## Feature: Welcome & Auth

### Deskripsi
Onboarding flow dan authentication. Mendukung email/password sign up, sign in, email OTP verification, username selection.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `welcome/welcome_flow.dart` | 2512 | Flow coordinator + semua screens + semua UI widgets |
| `auth/auth_repository.dart` | ~120 | Abstract class + AuthFailure types |
| `auth/supabase_auth_repository.dart` | ~400 | Supabase implementation |
| `auth/profile_remote_data_source.dart` | ~20 | Interface untuk remote profile operations |

### Key Classes

| Class | Tanggung Jawab |
|---|---|
| `WelcomeFlow` | StatefulWidget — flow coordinator. Mengelola page stack, transitions, auth callbacks. |
| `WelcomeAuthService` | Abstract — interface antara WelcomeFlow dan auth backend. |
| `WelcomeAuthRepositoryAdapter` | Adapter — wraps `AuthRepository` ke `WelcomeAuthService`. |
| `SupabaseAuthRepository` | Implementation — semua Supabase Auth & profile operations. |

### Dependencies

```
welcome_flow → WelcomeAuthService (injected)
WelcomeAuthRepositoryAdapter → AuthRepository (injected)
SupabaseAuthRepository → supabase_flutter, ProfileRemoteDataSource
```

### Auth Flow States

```
_WelcomeStep enum:
  welcome → loginMethod → emailLogin → emailVerification
                        → createAccount → createPassword → username → emailVerification
                        → verifyMethod → phoneNumber → whatsappOtp (belum aktif)
```

### Error Handling

| Error | Handling |
|---|---|
| Email already registered | Show error + suggest login |
| Username taken | Show 4 username suggestions |
| Wrong password | Show "Incorrect email or password" |
| OTP expired | Show error + enable resend button |
| Network error | Show generic error message |
| Supabase down | Show `UnavailableWelcomeAuthService` fallback (no-op auth) |

---

## Feature: Home / Feed

### Deskripsi
Timeline feed berisi post dari semua user. Mendukung like, save, buka comments, buka lokasi di peta.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `home/home_screen.dart` | ~300 | HomeScreen + header + composer entry |
| `home/widgets/feed_post_card.dart` | ~500 | FeedPostCard (reused di search dan profile) |
| `home/widgets/post_options_bottom_sheet.dart` | ~200 | Save/share/report bottom sheet |
| `feed_post_repository.dart` | ~180 | CRUD operations untuk feed_posts table |

### Key Classes

| Class | Tanggung Jawab |
|---|---|
| `HomeScreen` | Menampilkan feed post list + pull-to-refresh + floating check-in button. |
| `FeedPostCard` | Reusable card widget. Menampilkan author, topic, body, images, actions. |
| `FeedPostRepository` | SQLite CRUD. Auto-seed jika tabel kosong. |

### Callbacks ke Shell

| Callback | Trigger | Shell Response |
|---|---|---|
| `onPostCreated` | Post baru dibuat di NewPostScreen | `_refreshPostConsumers()` |
| `onPostUpdated` | Comment ditambah/dihapus | `_refreshPostConsumers()` |
| `onPostSaved` | Post disave/unsave | `_refreshPostConsumers()` |
| `onPostLiked` | Post dilike/unlike | `_refreshPostConsumers()` |
| `onOpenPostLocation` | Tap lokasi post | `_openPostLocationOnMap(post)` → switch tab |
| `onDownCheckIn` | Check-in baru dari camera | `_recordHeatmapLevel(point)` |

### Image Handling

Feed post mendukung 2 jenis gambar:
1. **Asset images** (`imageAsset`): Bundled di app, untuk seed data
2. **File images** (`imagePaths`): Foto dari kamera user, disimpan sebagai local file paths

Logic prioritas di `FeedPostCard`:
```
if imagePaths.isNotEmpty → tampilkan file images (carousel jika >1)
else if imageAsset.isNotEmpty → tampilkan asset image
```

---

## Feature: New Post

### Deskripsi
Composer untuk membuat post baru. Mendukung text, topic selection, location attachment, multiple photo attachment.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `new_post/new_post_screen.dart` | ~350 | NewPostScreen + post creation logic |
| `new_post/widgets/compose_header.dart` | ~100 | Header bar with close + post button |
| `new_post/widgets/compose_footer.dart` | ~100 | Bottom toolbar |
| `new_post/widgets/compose_tools.dart` | ~200 | Tool buttons (camera, location, topic) |
| `new_post/widgets/topic_autocomplete.dart` | ~150 | Topic picker dengan autocomplete |
| `new_post/widgets/attachment_media_strip.dart` | ~150 | Horizontal strip of attached photos |

### Post Creation Flow

```
User opens NewPostScreen
  → Writes body text
  → (Optional) Selects topic from autocomplete
  → (Optional) Attaches photos from camera
  → (Optional) Enables location (GPS)
  → Taps "Post"
    → FeedPostRepository.addPost(post)
    → Navigator.pop(true)
```

### Location Attachment

Saat user enable location:
1. Request GPS permission via `geolocator`
2. Get current position
3. Reverse geocode via `geocoding` package → display label
4. Store lat/lng + label di post

---

## Feature: Comments

### Deskripsi
Detail view untuk sebuah post + comment thread.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `comments/comment_screen.dart` | ~400 | CommentScreen + comment composer + comment list |
| `comment_repository.dart` | ~150 | CRUD operations untuk post_comments table |

### Key Behavior

- Buka dari: HomeScreen (tap post), SearchScreen (tap search result), ProfileScreen (tap post di tab)
- Return value: `pop(true)` jika ada perubahan (comment added/deleted)
- Auto-focus ke composer saat dibuka
- Comment author = current user (auto-fill initials + color)

---

## Feature: Map

### Deskripsi
Peta interaktif menampilkan feed check-ins, issue clusters, search lokasi, dan aksi checkout.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `map/map_screen.dart` | 2756 | MapScreen + semua map logic + semua overlay widgets |
| `map/widgets/activity_sheet.dart` | ~200 | Activity list bottom sheet |
| `map/widgets/impact_legend.dart` | ~100 | Legend for heatmap colors |
| `map/widgets/location_bubble.dart` | ~100 | Location tooltip |
| `map/widgets/map_marker.dart` | ~80 | Basic marker widget |
| `map/widgets/map_square_button.dart` | ~60 | Reusable map button |
| `map/widgets/waste_map_painter.dart` | ~120 | Custom painter for waste visualization |
| `check_in/capture_result_screen.dart` | ~300 | Camera capture + preview + submit |

### Map Components (inside map_screen.dart)

| Component | Baris (approx) | Deskripsi |
|---|---|---|
| `_MapScreenState` | 37-1150 | Core logic: location, search, clustering, camera animation |
| `_MapSearchBar` | ~200 | Search overlay dengan suggestions |
| `_CheckInBottomSheet` | ~150 | Draggable list of visible check-ins |
| `_CheckInDetailSheet` | ~200 | Detail view saat tap check-in |
| `_MapSheetSwitcher` | ~50 | AnimatedSwitcher for bottom sheets |
| `_CurrentLocationMarker` | ~30 | Pulsing blue dot |
| `_ActivityMarker` | ~40 | Icon marker for activities |
| `_FeedPostCheckInMarker` | ~40 | Avatar marker for post check-ins |
| `_FeedPostCheckInClusterMarker` | ~30 | Cluster count marker |
| `_IssueQuantityMarker` | ~40 | Sized circle for issue counts |
| `_LocateButton` | ~30 | "Center to my location" FAB |
| `_FlagCheckInButton` | ~30 | "New check-in" FAB |
| `_VisibleCheckIn` | ~100 | Data class for bottom sheet items |

### Map Tile Configuration

```dart
// Hierarchy (dari tertinggi prioritas):
1. --dart-define=MAP_TILE_URL_TEMPLATE=...       // Custom tile server
2. --dart-define=OSM_TILE_URL_TEMPLATE=...       // Legacy alias
3. Geoapify default (hardcoded API key)          // Fallback
```

### Location Search

1. User types query → debounce 420ms → Nominatim API autocomplete
2. User submits → try native `geocoding` package → fallback Nominatim search
3. Coordinate format detected? → Parse langsung tanpa API call

### Check-in Clustering

Feed check-in markers di-cluster berdasarkan zoom level:
- Zoom ≥ 17: Semua markers individual
- Zoom < 17: Cluster berdasarkan radius `90 × 2^(16-zoom)` meters

---

## Feature: Search

### Deskripsi
Search posts dan users dengan fuzzy ranking.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `search/search_screen.dart` | 1313 | SearchScreen + semua search logic + result widgets |
| `search/widgets/topic_row.dart` | ~60 | Topic display row |

### Search Engine

Menggunakan `fuzzy_search_engine` package:

```dart
SearchConfig(
  searchFields: ['name', 'subtitle', 'searchData'],
  fieldWeights: {'name': 1, 'subtitle': .75, 'searchData': .55},
)
```

### Search Behavior

| Tab | Data Source | Ranking |
|---|---|---|
| Semua | Posts + Users | Combined |
| Postingan | `FeedPostRepository.getPosts()` | Fuzzy match on title, body, author, topic, city, location |
| Pengguna | Extracted from post authors | Fuzzy match on username, display name, post content |

### Recent Search

- Disimpan di-memory (List, max 8 items)
- Tidak persisted ke storage
- Case-insensitive deduplication

---

## Feature: Profile

### Deskripsi
Halaman profil user dengan tabs konten, achievement badges, dan edit profile.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `profile/profile_screen.dart` | ~600 | ProfileScreen + 3 content tabs |
| `profile/edit_profile_screen.dart` | ~400 | Form edit profil (name, username, bio, location, photo) |
| `profile/achievement_screen.dart` | ~200 | Badge gallery |
| `profile/editable_profile.dart` | 46 | EditableProfile model |
| `profile/widgets/achievement_badge.dart` | ~80 | Individual badge widget |
| `profile/widgets/profile_meta.dart` | ~100 | Profile header (avatar, name, bio) |
| `profile/widgets/profile_placeholder.dart` | ~60 | Loading/error state placeholder |
| `profile/widgets/profile_stats.dart` | ~80 | Stats row (posts, check-ins, impact) |
| `profile/widgets/segmented_profile_tabs.dart` | ~100 | Tab bar for post/comment/saved views |
| `user_repository.dart` | ~200 | Profile CRUD (SQLite + Supabase) |

### Profile Tabs

| Tab | Data | Widget |
|---|---|---|
| Postingan | Posts by current user | FeedPostCard list |
| Komentar | Comments by current user | Comment card list |
| Tersimpan | Saved posts | FeedPostCard list with unsave action |

### Profile Data Priority

```
getCurrentUserProfile():
  1. Try Supabase (if connected) → EditableProfile
  2. Try SQLite (users table, is_current=1) → EditableProfile  
  3. Fallback → defaultProfile (Sarah Mae)
```

### Edit Profile Flow

```
ProfileScreen → tap "Edit Profile"
  → Navigator.push(EditProfileScreen)
    → User edits fields
    → Tap "Save"
      → UserRepository.saveCurrentUserProfile(profile)
        → If Supabase connected: update remote first
        → Update SQLite
      → Navigator.pop(updatedProfile)
    → ProfileScreen: detect pop result → update display
      → widget.onProfileUpdated(profile)
        → Shell: update _currentUserProfile → propagate to all screens
```

### Username Validation (Edit)

1. Check local: `UserRepository.getTakenUsernames()`
2. Check remote: `AuthRepository.isUsernameTaken(username)` (if available)
3. Case-insensitive comparison
4. If taken: show error, suggest alternatives

---

## Feature: Events (Skeleton)

### Deskripsi
Placeholder screen untuk fitur event/aktivitas di masa depan.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `event/event_screen.dart` | 10 | Scaffold kosong |

### Current Implementation

```dart
class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold();
}
```

### Planned Features (Future)

- Event listing dengan filter
- Event detail + RSVP
- Calendar view
- Integration dengan Map (event locations)

---

## Feature: Image Viewer

### Deskripsi
Fullscreen image viewer untuk melihat foto post.

### Files

| File | Baris | Deskripsi |
|---|---|---|
| `image_viewer/uploaded_image_fullscreen_page.dart` | ~200 | UploadedImageFullscreenPage |

### Key Behavior

- Buka dari: FeedPostCard (tap image)
- Support: asset images + file images + network images
- Gesture: pinch to zoom, drag to dismiss
- Background: semi-transparent black
