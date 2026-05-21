# Circul Screen Flow dan Struktur Refactor

Dokumen ini mencatat alur screen setelah refactor agar penambahan screen, widget, atau logic baru lebih mudah dilacak.

## Entry Point

- `lib/main.dart` menjalankan `CirculApp`.
- `CirculApp` memasang theme global dari `lib/core/constants.dart` dan membuka `CirculShell`.
- `CirculShell` mengatur tab utama dengan `IndexedStack`, sehingga state tiap tab tetap hidup saat pindah tab.
- Bottom navigation berada di `CirculBottomNav` dalam `main.dart`.

## Tab Utama

- Home: `lib/home/home_screen.dart`
  - Mengambil data lewat `FeedPostRepository`.
  - Membuka composer lewat `NewPostScreen`.
  - Render kartu feed memakai `lib/home/widgets/feed_post_card.dart`.
  - Tap area isi post atau icon komentar membuka `CommentScreen`.
- Peta: `lib/map/map_screen.dart`
  - Menampilkan peta interaktif berbasis OpenStreetMap tile API lewat `flutter_map`.
  - Overlay titik aktivitas dan heat impact masih dirender lokal di atas tile OSM.
  - Tile URL bisa diganti saat build lewat `OSM_TILE_URL_TEMPLATE` dan user-agent lewat `OSM_USER_AGENT_PACKAGE_NAME`.
  - Platform app harus punya izin internet; Android memakai `INTERNET`, macOS memakai entitlement `network.client`.
  - Tombol kanan bawah meminta izin lokasi lewat `geolocator`, lalu memusatkan peta ke lokasi pengguna.
  - Tombol flag di atas tombol lokasi membuka tray aksi `Check-in` dan `Check-out`.
- Cari: `lib/search/search_screen.dart`
  - Menampilkan search shell, chip trending, dan list topik dari `mock_data.dart`.
- Event: `lib/event/event_screen.dart`
  - Memakai data `nearbyActivities` dan komponen `ActivityCard` dari fitur map.
- Profil: `lib/profile/profile_screen.dart`
  - Menampilkan data profil statis, achievement, tab profil, dan preview post.

## Composer Post Baru

- Screen utama: `lib/new_post/new_post_screen.dart`.
- Header/footer/tools/topic autocomplete/attachment strip dipisah di `lib/new_post/widgets/`.
- Submit post masuk ke `FeedPostRepository.addPost`.
- Setelah submit sukses, screen composer `pop(true)`, lalu Home refresh `getPosts()`.
- Preview gambar lokal dan feed gambar lokal membuka `UploadedImageFullscreenPage` di `lib/image_viewer/`.

## Comment Screen

- Screen utama: `lib/comments/comment_screen.dart`.
- Dibuka dari Home melalui callback `FeedPostCard.onOpenComments`.
- `FeedPostCard` tetap reusable: jika `onOpenComments` tidak dikirim, kartu hanya tampil tanpa navigasi komentar.
- `CommentScreen` membaca dan menambah komentar lewat `CommentRepository`.
- Struktur SQLite komentar ada di tabel `post_comments`, terhubung ke `feed_posts.id` lewat `post_id`.
- Data `postComments` di `lib/mock_data.dart` dipakai sebagai seed/fallback untuk komentar awal.
- Composer bawah menyimpan komentar lokal ke SQLite dan menaikkan counter `comments` pada post terkait.

## Data dan Storage

- Model dan mock seed berada di `lib/mock_data.dart`.
- Warna global berada di `lib/core/constants.dart` dan di-export lagi oleh `mock_data.dart` untuk kompatibilitas import lama.
- Repository post berada di `lib/feed_post_repository.dart`.
- Repository komentar berada di `lib/comment_repository.dart`.
- SQLite setup berada di `lib/local_database.dart`.

## Shared Widgets

Widget yang dipakai lintas fitur berada di `lib/shared/` dan bisa diambil via barrel `lib/shared/shared_widgets.dart`:

- `CirculHeader` dan `CirculLogo`
- `SarahAvatar`
- `SearchFieldShell`
- `ChipButton`
- `SectionTitle`
- `NotificationIcon`

## Panduan Menambah Screen Baru

1. Buat folder fitur baru di `lib/<feature>/`.
2. Taruh screen utama sebagai `lib/<feature>/<feature>_screen.dart`.
3. Taruh komponen khusus fitur di `lib/<feature>/widgets/`.
4. Pindahkan widget ke `lib/shared/` hanya jika dipakai oleh minimal dua fitur.
5. Jika screen menjadi tab utama, import screen di `lib/main.dart`, tambahkan item ke list `screens`, lalu tambahkan `_NavItem` bottom navigation.
6. Jika butuh data lokal, buat method baru di repository terkait dan biarkan screen memanggil repository, bukan langsung database.

## Batas Tanggung Jawab Folder

- `core/`: token global seperti warna dan theme primitives.
- `shared/`: komponen lintas fitur tanpa logic bisnis spesifik.
- `home/`: feed dan entry point membuat post.
- `comments/`: detail post, daftar komentar, dan composer response.
- `new_post/`: logic compose post dan attachment.
- `image_viewer/`: preview fullscreen untuk image lokal.
- `map/`: OpenStreetMap view, overlay peta, dan activity card yang masih dipakai Event.
- `search/`: search/trending/topic discovery.
- `event/`: listing event dan aktivitas komunitas.
- `profile/`: profil user, achievement, statistik, dan tab profil.
