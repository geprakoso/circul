# Circul

Circul is a Flutter prototype for a community-powered circular action app. The goal is to help people document local environmental conditions, turn check-ins into visible map signals, and keep community action moving through posts, comments, events, and personal impact history.

The current app is local-first: it uses seeded mock data plus SQLite persistence so the core product flows can be explored before adding a backend.

## Product Goal

Circul focuses on making small sustainability actions visible and actionable:

- Share posts with the local community.
- Check in at a location with a camera capture and mark whether the environment is improving or needs attention.
- See check-ins, activities, and impact clusters on an OpenStreetMap-powered map.
- Comment on posts, like posts, save posts, and revisit user activity from the profile screen.
- Discover sustainability topics and nearby events.

## Main Screens

- **Home**: community feed, post composer entry, comments, saved/liked interactions, and quick check-in.
- **Peta**: interactive map, current location, check-in/check-out actions, visible issue clusters, and feed-linked map markers.
- **Cari**: topic discovery and search-oriented browsing.
- **Event**: nearby community activities.
- **Profil**: user profile, achievements, stats, posts, comments, and saved content.

## Tech Stack

- Flutter and Material 3
- `sqflite` for local persistence
- `flutter_map` and OpenStreetMap tiles
- `geolocator`, `geocoding`, and `latlong2` for location flows
- `image_picker` for camera-based check-ins
- `lottie` for animation assets

## Project Structure

```text
lib/
  main.dart                  App shell, theme, and bottom navigation
  mock_data.dart             Seed data and shared domain models
  local_database.dart        SQLite database setup and migrations
  feed_post_repository.dart  Feed post persistence
  comment_repository.dart    Comment persistence
  saved_post_repository.dart Saved post persistence
  liked_post_repository.dart Liked post persistence
  core/                      Global constants
  shared/                    Reusable UI widgets and helpers
  home/                      Feed and post cards
  new_post/                  Post composer
  comments/                  Comment detail screen
  check_in/                  Capture result and check-in posting flow
  map/                       OpenStreetMap view and map widgets
  search/                    Search and topic discovery
  event/                     Community event listing
  profile/                   Profile, stats, achievements, and tabs
```

More detail on the screen flow lives in [docs/screen_flow.md](docs/screen_flow.md).

## Getting Started

Install dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

Run static analysis:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

## Map Configuration

The map uses OpenStreetMap tiles by default:

```text
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

You can override the tile URL and user-agent package name at build time:

```sh
flutter run \
  --dart-define=OSM_TILE_URL_TEMPLATE=https://your-tile-server/{z}/{x}/{y}.png \
  --dart-define=OSM_USER_AGENT_PACKAGE_NAME=com.example.circul
```

Platforms that render map tiles need internet access enabled. Android includes the `INTERNET` permission, and macOS uses the network client entitlement.

## Local Data

The app stores local state in `circul.db` through `sqflite`. The database currently tracks:

- Feed posts
- Post comments
- Saved posts
- Liked posts

Seed content comes from `lib/mock_data.dart`, while new posts, comments, saves, likes, and check-in state are persisted locally.

## Current Status

Circul is an interactive prototype rather than a production service. The main product flows are implemented locally, while future backend work would likely add accounts, remote sync, moderation, notifications, and real event/community data.
