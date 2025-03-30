# Changelog

All notable bug fixes and improvements to the Flutter Messaging application are documented in this file.

## [Unreleased]

### Added
- Comprehensive documentation system with README files for each module and layer

## [1.0.0] - 2023-06-15

### iOS Simulator Build Fixes

#### Fixed
- **[Critical]** Resolved unsupported `-G` compiler flag issue in BoringSSL-GRPC causing iOS simulator build failures
  - Modified Podfile to remove the `-GCC_WARN_INHIBIT_ALL_WARNINGS` flag from BoringSSL-GRPC target's compiler settings
  - Fixes error: `unsupported option '-G' for target 'arm64-apple-ios12.0-simulator'`

- **[Major]** Fixed non-modular includes in framework modules error
  - Added `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES` to all build configurations in the Podfile
  - Added the same setting to the main project's `project.pbxproj` file
  - Resolves errors related to importing Firebase headers in non-modular contexts

- **[Major]** Addressed architecture compatibility issues on Apple Silicon Macs
  - Set `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64 i386` for simulator builds in debug mode
  - Fixed "Building for iOS Simulator, but linking in object file built for iOS" errors

- **[Medium]** Resolved Xcode 15 and iOS 17 compatibility issues
  - Disabled script sandboxing with `ENABLE_USER_SCRIPT_SANDBOXING = NO`
  - Disabled compiler index store with `COMPILER_INDEX_STORE_ENABLE = NO`
  - Fixes build failures introduced in newer Xcode versions

- **[Minor]** Improved CocoaPods integration
  - Set minimum iOS version to 12.0 in the Podfile
  - Disabled deprecated bitcode with `ENABLE_BITCODE = NO`
  - Updated pod clean-up and installation process

### Firebase and Authentication Issues

- **[Critical]** Fixed Firebase initialization failures on web platform
  - Implemented platform detection to skip Firebase initialization on web
  - Added mock repositories for web platform testing
  - Resolves Firebase SDK initialization errors in browser environment

- **[Major]** Resolved authentication state persistence issues
  - Fixed user session management to properly persist authentication state
  - Added proper error handling in authentication repository
  - Fixed "User not signed in" errors after app restart

- **[Medium]** Fixed anonymous authentication workflow
  - Corrected profile creation for anonymous users
  - Added proper display name for anonymous users
  - Resolved "Null user" errors in anonymous sign-in process

### UI and State Management

- **[Major]** Fixed message list rendering issues
  - Corrected message bubble alignment and styling
  - Implemented proper message timestamp formatting
  - Resolved message ordering inconsistencies

- **[Medium]** Addressed state management memory leaks
  - Fixed StreamSubscription cleanup in providers
  - Added proper dispose methods to controller classes
  - Resolved memory leaks in chat page implementation

- **[Medium]** Fixed dark mode theme inconsistencies
  - Updated color schemes for proper dark mode support
  - Fixed text contrast issues in dark mode
  - Ensured UI elements adapt correctly to theme changes

- **[Minor]** Improved responsive layout behavior
  - Fixed layout overflow issues on smaller screens
  - Improved keyboard handling in chat input
  - Fixed UI element sizing and spacing across different devices

### Data Layer and Network

- **[Major]** Fixed offline mode data synchronization
  - Implemented proper caching for offline access
  - Added queue system for pending messages
  - Resolved data loss issues when reconnecting

- **[Medium]** Addressed network error handling
  - Improved error propagation from data sources to UI
  - Added user-friendly error messages
  - Implemented retry logic for failed network operations

- **[Minor]** Fixed timestamp inconsistencies
  - Standardized DateTime handling across the application
  - Fixed timezone issues in message timestamps
  - Resolved "Invalid date" errors in message display

## [0.9.0] - 2023-05-01

### Initial Beta Release

- First beta version with core messaging functionality
- Known issues documented for future fixes

## How to Fix Common Issues

### iOS Simulator Build Issues

If you encounter iOS build issues:

1. **Clean the build**:
   ```
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```

2. **Fix compiler flags**:
   If you see unsupported `-G` flag errors, run:
   ```
   cd ios
   find . -name "*.xcconfig" -type f -exec sed -i '' 's/-G//g' {} \;
   ```

3. **Update Podfile**:
   Ensure your Podfile includes the fixes for BoringSSL-GRPC and architecture settings as documented in `docs/ios_specifics/README.md`

4. **Check Xcode settings**:
   For Xcode 15+ compatibility, disable script sandboxing and compiler index store in build settings

### Firebase Issues

1. **Web platform testing**:
   When testing on web, use the built-in mock repositories by updating `main.dart`:
   ```dart
   // Initialize mock repositories for web testing
   await initMockDependencies();
   ```

2. **Authentication state persistence**:
   If authentication state is not persisting, verify the implementation of `getCurrentUser()` in the auth repository

3. **Firebase initialization**:
   Ensure Firebase is properly initialized with the correct options from `firebase_options.dart`

### UI and Performance Issues

1. **Message list performance**:
   For large message lists, implement pagination and use `ListView.builder` with proper keys

2. **State management cleanup**:
   Always dispose controllers and cancel stream subscriptions in the `dispose()` method

3. **Memory leaks**:
   Use the Flutter DevTools to identify and fix memory leaks in your widgets and providers

## Reporting New Issues

When reporting new issues, please include:

1. **Environment information**:
   - Flutter and Dart versions
   - iOS/Android/Web platform and version
   - Device or simulator specifications

2. **Steps to reproduce**:
   - Detailed steps to reproduce the issue
   - Code snippets if applicable

3. **Expected vs. actual behavior**:
   - What you expected to happen
   - What actually happened

4. **Logs and screenshots**:
   - Relevant logs or console output
   - Screenshots or videos if applicable 