# ISPILO - Social Marketplace Platform

A modern Flutter-based mobile application with Spring Boot backend for a social marketplace platform featuring real-time messaging, product listings, and community engagement.

## 📚 Documentation

### Quick Links
- **[📖 Documentation Index](./DOCUMENTATION_INDEX.md)** - Complete guide to all documentation
- **[🔌 Backend API Specification](./BACKEND_API_SPECIFICATION.md)** - REST API contracts and data models
- **[🚀 Spring Boot Implementation](./SPRING_BOOT_IMPLEMENTATION.md)** - Backend setup with code examples
- **[🗄️ Database Migrations](./DATABASE_MIGRATIONS.md)** - SQL schemas and Flyway migrations
- **[📸 Camera & Voice Setup](./CAMERA_VOICE_PERMISSIONS.md)** - Platform permissions configuration

> **New to the project?** Start with the [Documentation Index](./DOCUMENTATION_INDEX.md) for a guided tour!

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.29.2 with Dart
- **State Management**: StatefulWidget with local state
- **Real-time**: WebSocket for live messaging
- **Offline Support**: SharedPreferences for pending messages
- **Media Handling**: Camera, voice notes, image picker

### Backend (Spring Boot) - In Development
- **Framework**: Spring Boot 3.2.0 with Java 17
- **Database**: MySQL 8.0+ with Flyway migrations
- **Caching**: Redis for performance
- **Authentication**: JWT with Spring Security
- **Real-time**: WebSocket with STOMP
- **File Storage**: AWS S3 for media

## 📋 Prerequisites

### Frontend
- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

### Backend (When implementing)
- Java 17+
- Maven 3.8+
- MySQL 8.0+ / PostgreSQL 14+
- Redis
- AWS S3 account

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🔁 Replacing the app launcher icon (quick)

1. Copy your PNG into the project:

```powershell
Copy-Item C:\Users\Admin\Downloads\Ispilo.png assets\images\Ispilo.png
```

2. (Optional) Create a white-background padded icon using the included Dart script:

```powershell
dart pub add image
dart run tooling\create_padded_icon.dart
```

3. Generate platform icons (uses flutter_launcher_icons configured in `pubspec.yaml`):

```powershell
flutter pub get
flutter pub run flutter_launcher_icons:main
```

4. Rebuild the app:

```powershell
flutter clean; flutter pub get; flutter build apk --release
```

If you prefer to use the unpadded image, open `pubspec.yaml` and set `flutter_icons.image_path` to `assets/images/Ispilo.png` before running the generator.


