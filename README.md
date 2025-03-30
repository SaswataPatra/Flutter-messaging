# Flutter Messaging App

A real-time messaging application built with Flutter and Firebase, implementing Clean Architecture principles with comprehensive documentation.

## Overview

Flutter Messaging is a 1:1 chat application that demonstrates modern Flutter development practices. The app features:

- **Real-time Messaging**: Send and receive messages instantly
- **User Authentication**: Email/password and anonymous sign-in options
- **User Profiles**: View and edit user profiles
- **Online Status**: Track user online/offline status
- **Clean Architecture**: Domain-driven design with clear separation of concerns

## Documentation Structure

This project includes comprehensive documentation to help developers understand the application's structure, implementation details, and design decisions:

```
docs/
├── README.md                     # Documentation system overview
├── CHANGELOG.md                  # Bug fixes and improvements history
├── modules/                      # Feature module documentation
│   ├── auth/README.md            # Authentication module
│   ├── messaging/README.md       # Messaging functionality
│   └── user_profile/README.md    # User profile management
├── libraries/                    # Shared libraries documentation
│   ├── data_layer/README.md      # Data sources, repositories implementations
│   ├── domain_layer/README.md    # Business entities, repository interfaces
│   └── presentation_layer/README.md # UI components and state management
├── architecture/README.md        # Overall architecture design and patterns
└── ios_specifics/README.md       # iOS-specific configurations and solutions
```

The documentation provides insights into every aspect of the application, from high-level architecture to specific implementation details of each module.

## Architecture

The project follows Clean Architecture principles, separating code into distinct layers:

1. **Domain Layer**: Contains business entities, repository interfaces, and use cases
2. **Data Layer**: Implements repositories and handles data sources (Firebase, local storage)
3. **Presentation Layer**: Manages UI components and state management using Riverpod

### Project Structure

```
lib/
├── core/            # Core functionality
│   ├── config/      # Configuration files
│   ├── network/     # Network related code
│   └── utils/       # Utility classes
├── data/            # Data layer
│   ├── datasources/ # Data sources implementation
│   ├── models/      # Data models
│   └── repositories/# Repository implementations
├── domain/          # Domain layer
│   ├── entities/    # Business entities
│   ├── repositories/# Repository interfaces
│   └── usecases/    # Use cases
└── presentation/    # Presentation layer
    ├── pages/       # UI pages
    └── widgets/     # Reusable widgets
```

## Key Technologies

- **Flutter**: UI framework for cross-platform development
- **Firebase**: Backend services including Authentication, Firestore, and Storage
- **Riverpod**: State management solution
- **Dartz**: Functional programming constructs (Either type for error handling)
- **GetIt**: Service locator for dependency injection
- **Equatable**: Value equality for entities and models

## Setup and Installation

### Prerequisites

- Flutter 3.7.0 or higher
- Dart 3.0.0 or higher
- Firebase account (for full functionality)

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/flutter-messaging.git
   cd flutter-messaging
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

For web testing, the app uses mock repositories by default, so you can run the app without Firebase configuration.

### Firebase Setup (Optional)

If you want to use Firebase services:

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication, Firestore, and Storage services
3. Install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Configure Firebase for your Flutter app:
   ```bash
   flutterfire configure
   ```
5. Update the Firebase initialization in `main.dart`

## Development

### Running Tests

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test --tags=widget

# Run integration tests
flutter test integration_test
```

### Code Generation

Some files in this project are generated. To regenerate them:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## iOS-Specific Considerations

This project includes special configurations for iOS, particularly for building on simulators. See `docs/ios_specifics/README.md` for detailed information on:

- Podfile configuration
- Compiler flag fixes
- Architecture settings for Apple Silicon Macs
- Xcode 15 and iOS 17 compatibility fixes

## Bug Fixes and Known Issues

We maintain a detailed changelog of all bug fixes and improvements. For information about resolved issues, workarounds, and troubleshooting steps, see `docs/CHANGELOG.md`.

## Contributing

Contributions are welcome! Please check out our contribution guidelines:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The Flutter team for their excellent framework
- Firebase for providing backend services
- All the open-source packages used in this project
- The community for their support and contributions

---

For detailed documentation on specific aspects of the application, please refer to the respective README files in the `/docs` directory. 