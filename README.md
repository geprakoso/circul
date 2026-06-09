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

## Supabase Auth Redirect

Email verification links redirect back to the app with:

```text
com.example.circul://login-callback
```

Add that URL to **Supabase Dashboard > Authentication > URL Configuration > Redirect URLs**. The app also supports overriding it at build time:

```sh
flutter run --dart-define=SUPABASE_EMAIL_REDIRECT_TO=com.example.circul://login-callback
```

For development with SMTP providers that rewrite links, use an OTP code in the
Supabase **Confirm signup** email template instead of a clickable verification
link:

```html
<h2>Verify your Circul email</h2>
<p>Your verification code is:</p>
<h1>{{ .Token }}</h1>
```

The app verifies that 6-digit code directly with Supabase.

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

## Changelog

### 0.0.10 - 2026-05-27

- Added profile feed visibility for user posts.
- Improved global feed post elements and post card actions.
- Added reply, save, and like capabilities on feed posts.
- Added like button animation and refreshed seasonal button animation behavior.
- Hid activity content that is not ready for the current prototype.
- Updated the README to describe the current Circul product goal, setup, structure, and local-first status.

### 0.0.9 - 2026-05-25

- Completed the capture result flow for check-ins.
- Fixed topic behavior on the search screen.

### 0.0.8 - 2026-05-24

- Improved UI scale across the app, including the home screen and comment section.
- Added macOS dummy camera support for local development.
- Added placeholder imagery for capture and preview flows.
- Connected map cards so location posts can open directly on the map.
- Added a bottom sheet for nearby check-ins.

### 0.0.7 - 2026-05-22

- Added the check-in button and home floating check-in action.
- Added animated locate-me and flag controls on the map.
- Added location coordinate input for captured check-ins.

### 0.0.6 - 2026-05-21

- Implemented the OpenStreetMap-based map screen.
- Added map tile rendering, location-centered interaction, and local impact visualization foundations.

### 0.0.5 - 2026-05-20

- Added feed topics.
- Refactored the screen structure into feature folders.
- Added the comment screen and fixed comment submission.

### 0.0.4 - 2026-05-19

- Added image upload routing and scrollable uploaded image previews.
- Added fullscreen picture preview.
- Fixed missing picture routing.

### 0.0.1 - 2026-05-18

- Initial runnable Flutter project created.
- App can be opened and run as the first accessible Circul prototype.
