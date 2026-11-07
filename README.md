# Wayfarer

A local outings and trip planning application built with Flutter.

## Overview

Wayfarer is a trip-planning application designed to help users manage their travel itineraries in a single place. The application allows users to plan trips, organize destinations and activities, and keep track of important travel information. Wayfarer aims to simplify trip planning by combining itineraries, maps, weather updates, and travel reminders into a single mobile application.

## Features

### Core Features
- Multi-screen navigation
- Trip creation and itinerary management
- Date and time pickers
- Snackbars and notifications
- Local storage
- Cloud synchronization
- Places and weather integration via HTTP requests

### Advanced Features
- Maps
- Geolocation
- Geocoding
- Route visualization

## Technologies
- Flutter
- Firebase Authentication
- Firebase Firestore
- Firebase Cloud Messaging
- Hive / SQLite
- Google Maps API
- Google Places API
- OpenWeatherMap API

## Team Members
| ID | Name | Role |
|------|------|------|
| 100869700 | Suryansh Saroch | Backend / Cloud Lead |
| 100918296 | Christopher Kiige | Frontend / Navigation Lead |
| 100915823 | Brandan Stradling | Maps & Geolocation Lead |
| 100865485 | Justin See | UI/UX & QA Lead |
| 100876550 | Charis Chan | Testing / Documentation Lead |

## How to run (Part 2 check-in build)
1. Install Flutter (stable, 3.35 or newer) and start an Android emulator or plug in a phone.
2. From the project folder:
   ```
   flutter pub get
   flutter run
   ```
3. The device needs internet for live weather and map tiles. Everything else works offline.

**Test account:** none needed. There is no login yet; the app opens straight into Discover with sample trips loaded. To get back to the demo data at any time: Profile → *Reset sample data*.

## Project structure
```
lib/
  main.dart              app entry, theme + text size from Settings
  theme.dart             Material 3 theme built from the chosen accent colour
  models/                Place, Trip, TripStop (with JSON for storage)
  data/                  sample places around Oshawa + demo trips
  state/                 AppState, SettingsController, TripStore (ChangeNotifiers)
  services/              WeatherService (HTTP, Open-Meteo)
  screens/               Discover, Place detail, Trips, Trip detail, Trip form,
                         Map, Profile, Settings, HomeShell (bottom nav)
  widgets/               App drawer, place card, stop editor dialog, empty state
```

## Third-party services
- **Open-Meteo** for current weather (free, no API key).
- **OpenStreetMap** tiles via `flutter_map` (no API key). © OpenStreetMap contributors.
- Local storage with `shared_preferences`.

## Generative AI use

