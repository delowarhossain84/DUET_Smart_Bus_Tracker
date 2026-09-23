# DUET Smart Bus Tracker — Flutter Frontend

This folder is the Flutter mobile frontend for the DUET Smart Bus Tracker.

## Current backend

The frontend is configured to use the deployed FastAPI backend:

`https://duet-bus-tracker.onrender.com`

The Base URL is intentionally kept in one place:

`lib/services/auth_service.dart`

```dart
static const String baseUrl = "https://duet-bus-tracker.onrender.com";
```

## Main features

- Student / Teacher / Driver / Admin role-based UI
- Login and registration
- Persistent login session
- Student active-trip list
- Google Maps live tracking screen
- Student GPS sharing over WebSocket
- Driver GPS streaming
- Driver route and bus loading
- Admin dashboard, routes, stops, buses and driver management
- Responsive Material 3 UI

## Important frontend/backend compatibility fixes included

- Production WebSocket uses `wss://` when the backend uses HTTPS.
- WebSocket sends the required `Authorization: Bearer ...` header.
- Student WebSocket location messages include the backend-required `type: location_update`.
- Student registration no longer creates a fake authenticated session when the backend returns no access token; the user is sent to Login after registration.
- Student trip parsing understands the backend's nested `route` response.
- Admin route loading uses the actual `/api/v1/admin/routes` endpoint.
- Debug logging no longer prints access-token contents.

## Run

```bash
flutter pub get
flutter run
```

For an Android release build:

```bash
flutter build apk --release
```

## Important backend-contract limitations

The backend is intentionally **not modified** by this frontend package.

1. The backend driver `POST /api/v1/driver/trips/start` currently returns a successful response without returning the newly generated `trip_id`. The backend generates the trip ID server-side. Because the driver location API requires that exact trip ID, true driver GPS tracking cannot be made fully functional from the frontend alone until the backend returns the created trip ID (or provides another driver-accessible way to retrieve the active trip).

2. The backend currently has no alerts endpoint. Therefore the existing alerts UI cannot be converted into live server alerts without a backend API.

3. The backend currently has no admin endpoint for creating/dispatching a trip from the admin dashboard. The frontend's existing dispatch UI is therefore local/demo behavior.

4. The backend refresh-token endpoint is currently commented out. Access tokens are short-lived, so the frontend cannot implement automatic token refresh without a backend refresh endpoint.

These are documented rather than hidden because changing the backend was explicitly excluded from this frontend update.
