# Flutter Messaging App

A 1:1 messaging application built with Flutter and Firebase, featuring real-time messaging, online status indicators, and a clean UI. This app follows Clean Architecture principles and uses Riverpod for state management.

## Features

- **User Authentication**
  - Email/password authentication
  - Anonymous sign-in
  - Profile management

- **Real-time Messaging**
  - Text messages with emoji support
  - Message status indicators (sent, delivered, read)
  - Typing indicators
  - Message timestamps
  - Message history

- **User Status**
  - Online/offline status
  - Last seen timestamp
  - User profile viewing

- **UI/UX**
  - Clean, intuitive interface
  - Dark/light mode support
  - Real-time updates

## Tech Stack

- **Frontend**
  - Flutter for cross-platform UI
  - Riverpod for state management
  - Clean Architecture pattern

- **Backend**
  - Firebase Authentication
  - Cloud Firestore for data storage
  - Firebase Storage for media files
  - Firebase Cloud Messaging for notifications

## Project Structure

The project follows Clean Architecture principles, separating code into distinct layers:

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
    ├── bloc/        # State management
    ├── pages/       # UI pages
    └── widgets/     # Reusable widgets
```

## Architecture Overview

This app follows Clean Architecture principles, with these key components:

1. **Entities** - Core business objects like User and Message
2. **Use Cases** - Business rules that orchestrate the flow of data
3. **Repositories** - Interfaces that abstract the data sources
4. **Data Sources** - Implementations that fetch data from Firebase
5. **Presentation** - UI components and state management

## Setup and Installation

### Prerequisites

- Flutter 3.7.0 or higher
- Dart 3.0.0 or higher
- Firebase account

### Firebase Setup

1. Create a new Firebase project
2. Add Android and iOS apps to your Firebase project
3. Download and add the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files
4. Enable Authentication (Email/Password and Anonymous)
5. Create a Firestore database

### Running the App

1. Clone the repository:
```bash
git clone https://github.com/yourusername/flutter-messaging.git
cd flutter-messaging
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Firebase Security Rules

Here are the recommended Firestore security rules for this application:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - can be read by anyone, only updated by the owner
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }
    
    // Messages - can be read and written by sender and receiver
    match /messages/{messageId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.senderId || 
        request.auth.uid == resource.data.receiverId
      );
      allow create: if request.auth != null && request.auth.uid == request.resource.data.senderId;
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.senderId || 
        request.auth.uid == resource.data.receiverId
      );
      allow delete: if false;
    }
    
    // Chats - accessible only to participants
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        chatId.matches(request.auth.uid + '_.*') || chatId.matches('.*_' + request.auth.uid);
      
      // Chat messages
      match /messages/{messageId} {
        allow read, write: if request.auth != null && (
          request.auth.uid == resource.data.senderId || 
          request.auth.uid == resource.data.receiverId
        );
      }
    }
    
    // Typing status - accessible only to participants
    match /typing_status/{chatId} {
      allow read, write: if request.auth != null && 
        chatId.matches(request.auth.uid + '_.*') || chatId.matches('.*_' + request.auth.uid);
    }
  }
}
```

## Performance Optimization

The app implements several performance optimization strategies:

1. **Message Pagination**: Loading a limited number of messages at a time
2. **Offline Support**: Using Firestore's offline capabilities
3. **Caching**: Implementing local caching for frequently accessed data
4. **Lazy Loading**: Loading data only when needed

## Error Handling Strategy

The app uses a unified error handling approach:

1. **Failure Objects**: Using the Result pattern (Either type) to handle failures
2. **Typed Exceptions**: Creating specific exception types for different error scenarios
3. **User-Friendly Messages**: Converting technical errors into user-friendly messages
4. **Retry Mechanisms**: Implementing retry logic for network operations
5. **Logging**: Comprehensive error logging for debugging

## Testing

The project includes three levels of testing:

1. **Unit Tests**: Testing individual components like repositories and use cases
2. **Widget Tests**: Testing UI components in isolation
3. **Integration Tests**: Testing full user flows

## Deployment Checklist

Before deploying to app stores:

1. **Firebase Configuration**: Ensure all Firebase services are properly configured
2. **Security Rules**: Review and update Firestore security rules
3. **Performance Testing**: Check performance on various devices
4. **Error Handling**: Verify all error scenarios are properly handled
5. **Authentication**: Test all authentication flows
6. **Data Privacy**: Ensure user data is properly protected
7. **App Permissions**: Review and minimize required permissions
8. **Analytics**: Set up Firebase Analytics for monitoring

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter and Dart teams for the excellent framework
- Firebase team for the backend services
- All the open-source packages used in this project
