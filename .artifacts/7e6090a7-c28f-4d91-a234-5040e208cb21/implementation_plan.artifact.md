# Implementation Plan - Persistent Authentication

Implement local storage to save the authentication token and user profile, allowing users to remain logged in across app restarts.

## User Review Required

> [!IMPORTANT]
> **New Dependency:** I will add the `shared_preferences` package to `pubspec.yaml` to handle local data storage.
> **Auto-Login:** When the app starts, it will check for a saved token. If found, it will automatically navigate to the Home screen (MainScreen or DriverScreen) instead of the Login screen.

## Proposed Changes

### [Dependencies]

#### [MODIFY] [pubspec.yaml](file:///G:/android_project/DUET_project/Bus_Tracker_New/bus_tracker_frontend/pubspec.yaml)
*   Add `shared_preferences: ^2.3.2` to the dependencies section.

### [Services]

#### [MODIFY] [auth_service.dart](file:///G:/android_project/DUET_project/Bus_Tracker_New/bus_tracker_frontend/lib/services/auth_service.dart)
*   Add `saveSession()`: Saves `bearerToken` and `AppUser` (as JSON string) to SharedPreferences.
*   Add `loadSession()`: Reads the saved token and user data when the app initializes.
*   Add `clearSession()`: Removes saved data on logout.
*   Update `login()` and `registerUser()` to call `saveSession()` on success.

### [App Initialization]

#### [MODIFY] [main.dart](file:///G:/android_project/DUET_project/Bus_Tracker_New/bus_tracker_frontend/lib/main.dart)
*   Initialize `AuthService.loadSession()` inside `main()` before `runApp()`.

#### [MODIFY] [splash_screen.dart](file:///G:/android_project/DUET_project/Bus_Tracker_New/bus_tracker_frontend/lib/splash_screen.dart)
*   Update logic to check `AuthService.currentUser`.
*   If a user is already logged in, navigate directly to the appropriate screen (Admin, Driver, or Student).

## Verification Plan

### Automated Tests
*   Run `flutter pub get` to ensure the new dependency is installed correctly.

### Manual Verification
1.  **Login:** Log in to the app (e.g., as a Student).
2.  **Restart:** Close the app completely and reopen it.
3.  **Result:** Verify that the app opens directly to the Home screen without asking for credentials.
4.  **Logout:** Tap logout and verify that restarting the app now shows the Login screen.
