# Project Manager — Mobile App (Android)

A modern, Android-first task and project management client built with Flutter and Material 3. It consumes the Express REST API backend and provides real-time dashboard metrics, project tracking, and full task lifecycle management (create, update, mark complete, filter, and delete).

---

## Features

- **Dashboard**: High-level overview with 5 metric cards (Total Projects, Total Tasks, Completed Tasks, Pending Tasks, Projects In Progress), greeting, and pull-to-refresh.
- **Projects**: Searchable and filterable list of user projects with date ranges, task counts, and detailed project view.
- **Tasks**: Cross-project and project-specific task lists with 400ms debounced search, status and priority filter chips, and interactive completion toggle.
- **Task Management**: Modal form for creating and editing tasks with input validation, server error feedback, and due date picker.
- **Offline & Error Resilience**: Network connectivity banners, structured exception handling, and auto-logout on session expiration (401).

---

## Requirements

- **Flutter**: `3.47.6` (Channel stable) or higher
- **Dart**: `3.13.5` or higher
- **Android**: Android device or emulator with **minSdk 23+** (Android 6.0+) and an active internet connection.

---

## Getting Started

1. Navigate to the `mobile` directory:
   ```bash
   cd mobile
   ```

2. Install all dependencies:
   ```bash
   flutter pub get
   ```

---

## Running the App

### Default (Production Cloud Backend)
Runs against the hosted backend on Render:
```bash
flutter run
```

### With Custom or Local API URL
Pass the `API_URL` environment flag at runtime:

- **Local Android Emulator** (`10.0.2.2` maps to your host machine `localhost`):
  ```bash
  flutter run --dart-define=API_URL=http://10.0.2.2:5000/api
  ```
- **Physical Android Device** (replace with your machine's local Wi-Fi IP):
  ```bash
  flutter run --dart-define=API_URL=http://192.168.1.5:5000/api
  ```

> **Note on Free-Tier Backend:** The hosted Render backend (`https://backend-for-project-management.onrender.com/api`) runs on a free tier and spins down when idle. The very first request after inactivity may take up to **60 seconds** to wake up.

---

## Building the APK

To generate a standalone release APK:
```bash
flutter build apk --release --dart-define=API_URL=https://backend-for-project-management.onrender.com/api
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

To build a debug APK for fast local testing:
```bash
flutter build apk --debug
```
