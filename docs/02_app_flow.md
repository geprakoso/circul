# 02 — App Flow & Navigation

> **Scope**: User journey, screen flow diagram, navigation rules, tab behavior  
> **Audience**: Semua developer, designer, product  
> **Terakhir diupdate**: 2026-06-09

---

## High-Level User Journey

```
[ App Launch ]
      │
      ▼
[ Supabase Init ]──── gagal ──→ [ WelcomeFlow tanpa auth ]
      │
      ▼
[ Cek Session ]
      │
  ┌───┴───────────┐
  │               │
  ▼               ▼
[ Ada Session ]  [ Tidak Ada Session ]
  │               │
  ▼               ▼
[ CirculShell ]  [ WelcomeFlow ]
  (Main App)       │
                   ▼
              ┌─────────────┐
              │ Login Method │
              └──┬──────┬───┘
                 │      │
            Email/Pass  Create Account
                 │      │
                 ▼      ▼
              [ Sign In ] [ Sign Up Flow ]
                 │             │
                 │        ┌────┼────┐
                 │        │    │    │
                 │     Email  Name  Password  Username
                 │        │    │    │         │
                 │        └────┴────┘         │
                 │             │              │
                 │             ▼              │
                 │    [ Email Verification ]  │
                 │        (OTP 8 digit)       │
                 │             │              │
                 └──────┬──────┘              │
                        │                     │
                        ▼                     │
                  [ CirculShell ]  ◄───────────┘
                   (Main App)
```

---

## Auth Gate Logic

File: `lib/main.dart` → `_AuthGate` widget

```dart
if (!isAuthenticated) → WelcomeFlow
if (isAuthenticated)  → CirculShell
```

`isAuthenticated` ditentukan oleh `authRepository.hasActiveSession`, yang mengecek apakah ada `currentSession` aktif di Supabase client.

---

## Welcome Flow Detail

File: `lib/welcome/welcome_flow.dart`

Flow dikendalikan oleh enum `_WelcomeStep` dan stack `_history` untuk navigasi back.

```
welcome ──→ loginMethod ──→ emailLogin ──→ [signIn success] ──→ onComplete()
                │                │
                │                └──→ [email not verified] ──→ emailVerification
                │
                ├──→ createAccount ──→ createPassword ──→ username ──→ emailVerification
                │        │
                │        └──→ [email taken] ──→ error message
                │
                ├──→ (Google login - belum aktif)
                └──→ (Apple login - belum aktif)
```

### Step Transitions

| From | To | Trigger |
|---|---|---|
| `welcome` | `loginMethod` | Tap "Start Check-in" |
| `loginMethod` | `emailLogin` | Tap "Login using Email" |
| `loginMethod` | `createAccount` | Tap "Create an account" |
| `emailLogin` | `onComplete()` | Sign in success |
| `emailLogin` | `emailVerification` | Email belum diverifikasi |
| `createAccount` | `createPassword` | Email valid + name valid + email not taken |
| `createPassword` | `username` | Password meets requirements |
| `username` | `emailVerification` | Sign up success |
| `emailVerification` | `onComplete()` | OTP verified |

### Back Navigation

Setiap `_go(step)` push step lama ke `_history`. `_back()` pop dari `_history`. Animasi slide horizontal berdasarkan `_transitionDirection`.

---

## Main App (CirculShell)

File: `lib/main.dart` → `CirculShell` widget

### Tab Structure

```
┌─────────────────────────────────────┐
│                                     │
│         IndexedStack                │
│    (semua tab hidup bersamaan)      │
│                                     │
│  [0] HomeScreen                     │
│  [1] MapScreen                      │
│  [2] SearchScreen                   │
│  [3] EventScreen                    │
│  [4] ProfileScreen                  │
│                                     │
├─────────────────────────────────────┤
│  CirculBottomNav                    │
│  Home  Peta  Cari  Event  Profil   │
└─────────────────────────────────────┘
```

### Tab Behavior

| Tab | Index | Icon | Behavior saat di-tap |
|---|---|---|---|
| Home | 0 | `home` | Standard tab switch |
| Peta | 1 | `flag` | Clear `_focusedCheckIn`, increment `_mapCurrentLocationRefreshToken`, reload location |
| Cari | 2 | `search` | Jika sudah di tab Cari, increment `_searchResetToken` (reset ke landing) |
| Event | 3 | `calendar` | Standard tab switch |
| Profil | 4 | `person` (avatar jika ada foto) | Increment `_profileRefreshToken`, reload data |

### Tab 4 (Profil) — Avatar di Bottom Nav

Jika user punya `imagePath` di profil, bottom nav menampilkan foto avatar alih-alih icon person. Fallback ke `SarahAvatar` jika gambar error.

---

## Screen-by-Screen Detail

### Home Screen (`lib/home/home_screen.dart`)

```
┌────────────────────────────┐
│ CirculHeader + Notification │
├────────────────────────────┤
│ Composer Entry             │──tap──→ Navigator.push → NewPostScreen
├────────────────────────────┤
│ Feed Post Card #1          │──tap body──→ Navigator.push → CommentScreen
│                            │──tap location──→ callback → map tab
│                            │──tap image──→ Navigator.push → ImageViewer
│                            │──tap like──→ toggle like (SQLite)
│                            │──tap save──→ via PostOptionsBottomSheet
│                            │──tap more──→ showPostOptionsBottomSheet
├────────────────────────────┤
│ Feed Post Card #2          │
│ ...                        │
├────────────────────────────┤
│ Floating Check-in Button   │──tap──→ Camera → CaptureResultScreen
└────────────────────────────┘
```

**Data flow**: `FeedPostRepository.getPosts()` → List<FeedPost> → `FeedPostCard` widgets

### Map Screen (`lib/map/map_screen.dart`)

```
┌────────────────────────────┐
│ MapSearchBar (top overlay) │──search──→ Nominatim API → pan to result
├────────────────────────────┤
│                            │
│     FlutterMap              │
│     ├── TileLayer (Geoapify/OSM)
│     ├── CircleLayer (heatmap glows)
│     ├── MarkerLayer         │
│     │   ├── Current location marker
│     │   ├── Activity markers
│     │   ├── Feed check-in markers (clustered)
│     │   ├── Issue cluster markers
│     │   ├── Focused check-in marker
│     │   └── Search result marker
│     └── Attribution         │
│                            │
├────────────────────────────┤
│ [Locate Button]  [Flag]    │──flag tap──→ Camera → CaptureResultScreen
├────────────────────────────┤
│ Check-in Bottom Sheet      │──item tap──→ Check-in Detail Sheet
│ (jika ada visible check-ins)│             ├── checkout button → Camera
│                            │             └── close → kembali ke list
└────────────────────────────┘
```

**Data flow**:
- Issue clusters: dari `_CirculShellState._issueClusters` (in-memory)
- Feed check-ins: `FeedPostRepository.getPosts()` → filter `locationEnabled && !checkoutCompleted`
- Map tiles: Geoapify API (atau custom via `--dart-define`)
- Location search: Nominatim OpenStreetMap API

### Search Screen (`lib/search/search_screen.dart`)

```
State 1: Landing
┌────────────────────────────┐
│ "Search" Title             │
│ Search Input               │
│ "Recent search" chips      │
└────────────────────────────┘

State 2: Results (setelah submit)
┌────────────────────────────┐
│ Search Input + "Batal"     │
│ Tabs: Semua | Postingan | Pengguna
├────────────────────────────┤
│ Postingan Results          │──tap──→ CommentScreen
│ Pengguna Results           │
└────────────────────────────┘
```

**Search engine**: `fuzzy_search_engine` package — fuzzy search across `name`, `subtitle`, `searchData` fields with weighted scoring.

### Event Screen (`lib/event/event_screen.dart`)

Saat ini **placeholder** (286 bytes). Menampilkan `Scaffold` kosong. Akan diisi di fase selanjutnya.

### Profile Screen (`lib/profile/profile_screen.dart`)

```
┌────────────────────────────┐
│ CirculHeader + Settings    │──settings tap──→ (belum ada)
├────────────────────────────┤
│ Profile Avatar + Name      │
│ @username                  │
│ Bio                        │
│ Location                   │
│ "Edit Profile" button      │──tap──→ EditProfileScreen
├────────────────────────────┤
│ ProfileStats               │
│ (Posts, Check-ins, Impact) │
├────────────────────────────┤
│ Achievement Badges         │──tap──→ AchievementScreen
├────────────────────────────┤
│ SegmentedProfileTabs       │
│ Postingan | Komentar | Tersimpan
├────────────────────────────┤
│ Post cards / Comment cards │
│ / Saved post cards         │
└────────────────────────────┘
```

---

## Cross-Feature Navigation

### Post → Map Flow

Saat user tap lokasi di feed post card:

```
HomeScreen
  → FeedPostCard.onOpenLocation(post)
    → _CirculShellState._openPostLocationOnMap(post)
      → setState: _focusedCheckIn = MapFocusedCheckIn(...)
      → setState: _index = 1 (switch to Map tab)
        → MapScreen.didUpdateWidget: detect focusedCheckIn changed
          → _animateMapTo(focusedCheckIn.point)
```

### Post Create → Multi-Tab Refresh Flow

Saat user buat post baru:

```
NewPostScreen
  → FeedPostRepository.addPost(post)
  → Navigator.pop(true)
    → HomeScreen: detect pop result true
      → widget.onPostCreated()
        → _CirculShellState._refreshPostConsumers()
          → _homeRefreshToken++ → HomeScreen reload
          → _profileRefreshToken++ → ProfileScreen reload
```

### Check-in → Heatmap Flow

```
CaptureResultScreen
  → submit check-in post with location
  → Navigator.pop(CheckInResult)
    → MapScreen: receive result
      → widget.onDownCheckIn(latLng)
        → _CirculShellState._recordHeatmapLevel(point)
          → _issueClusters.add/update cluster
          → MapScreen re-renders with new cluster
```

---

## Deep Link & External Entry

| URL Scheme | Handler | Status |
|---|---|---|
| `com.example.circul://login-callback` | Supabase email verification redirect | ✅ Aktif |
| Deep links ke screen tertentu | Belum diimplementasi | ❌ Belum ada |

---

## Error States per Screen

| Screen | Error State | Handling |
|---|---|---|
| WelcomeFlow | Auth failure | Tampilkan `_WelcomeErrorText` inline |
| WelcomeFlow | Email taken | Tampilkan error + suggest login |
| WelcomeFlow | Username taken | Tampilkan suggestions (4 alternatif) |
| WelcomeFlow | OTP expired | Tampilkan error + resend button |
| Home | Feed load failed | Tampilkan `const []` (feed kosong) |
| Map | Location permission denied | Silent fail, tetap di default location |
| Map | Geocoding failed | Show snackbar "Lokasi tidak ditemukan" |
| Profile | Profile load failed | Gunakan `defaultProfile` (Sarah Mae) |
