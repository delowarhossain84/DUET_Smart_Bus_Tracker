# Backend Contract Notes

This document records items that cannot be completed by frontend-only changes.

## 1. Driver trip start

The deployed backend endpoint:

`POST /api/v1/driver/trips/start`

creates a server-side `trip_id`, but its current response does not include that ID. The frontend therefore cannot know the exact trip ID required by:

`POST /api/v1/driver/location`

and cannot safely start the live driver telemetry flow.

## 2. Student WebSocket

The frontend now sends:

```json
{
  "type": "location_update",
  "lat": 0,
  "lng": 0
}
```

and connects using the Bearer token because the backend requires both.

## 3. Alerts

No backend alerts endpoint is present, so live alerts require a future backend API.

## 4. Admin trip dispatch

No backend endpoint is present for creating a trip from the admin dashboard.

## 5. Token refresh

The backend login access token is short-lived and the refresh endpoint is currently disabled/commented out. Automatic refresh cannot be implemented solely in the frontend.
