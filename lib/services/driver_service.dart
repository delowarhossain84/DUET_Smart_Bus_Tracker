import 'dart:async'; // Async operation এবং StreamSubscription ব্যবহারের জন্য।
import 'package:flutter/foundation.dart'; // Android platform check করার জন্য।
import 'package:geolocator/geolocator.dart'; // GPS location নেওয়ার জন্য।
import 'package:http/http.dart' as http; // Backend API call করার জন্য।
import 'dart:convert'; // JSON encode/decode করার জন্য।
import 'package:duet_smart_bus_tracker/services/auth_service.dart'; // Login token এবং backend URL ব্যবহারের জন্য।

class DriverService {
  StreamSubscription<Position>? _positionStreamSubscription; // GPS stream বন্ধ করার জন্য subscription রাখে।
  bool isTracking = false; // GPS tracking চলছে কিনা রাখে।
  String? currentTripId; // Current trip ID রাখে।

  static Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled(); // Phone GPS চালু আছে কিনা check করে।
    if (!serviceEnabled) return false; // GPS বন্ধ থাকলে tracking শুরু করে না।

    LocationPermission permission = await Geolocator.checkPermission(); // বর্তমান location permission check করে।

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // Permission না থাকলে user-এর কাছে permission চায়।
      if (permission == LocationPermission.denied) return false; // Permission না দিলে tracking বন্ধ করে।
    }

    return permission != LocationPermission.deniedForever; // Permanently denied হলে false দেয়।
  }

  Future<bool> startTrip(int busId, int routeId) async {
    // Real backend ব্যবহার না করলে trip সফল ধরা হবে।
    if (!AuthService.useRealBackend) return true;

    try {
      // Backend-এর trip start API URL।
      final url = Uri.parse(
        "${AuthService.baseUrl}/api/v1/driver/trips/start",
      );

      // Backend-এ trip start request পাঠানো।
      print("ENDING TRIP ID: $currentTripId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (AuthService.bearerToken != null)
            "Authorization": "Bearer ${AuthService.bearerToken}",
        },
        body: jsonEncode({
          "bus_id": busId,
          "route_id": routeId,
          "device_id": "device-mobile-duet",
          "app_version": "v1.0",
        }),
      );

      // Request সফল হলে।
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend response JSON-এ convert করবে।
        final data = jsonDecode(response.body);

        // প্রথমে সরাসরি trip_id খুঁজবে।
        if (data['trip_id'] != null) {
          currentTripId = data['trip_id'].toString();
        }
        // data-এর ভিতরে trip_id খুঁজবে।
        else if (data['data'] != null &&
            data['data']['trip_id'] != null) {
          currentTripId = data['data']['trip_id'].toString();
        }

        // পাওয়া Trip ID দেখাবে।
        print("NEW TRIP ID: $currentTripId");

        // Backend response দেখাবে।
        print("START TRIP RESPONSE: ${response.body}");

        // Trip ID না পাওয়া গেলে false return করবে।
        if (currentTripId == null || currentTripId!.isEmpty) {
          print("ERROR: Trip ID was not returned by backend.");
          return false;
        }

        // Trip সফলভাবে শুরু হয়েছে।
        print("TRIP STARTED: $currentTripId");

        return true;
      }

      // Backend error হলে।
      print("Start Trip STATUS: ${response.statusCode}");
      print("Start Trip RESPONSE: ${response.body}");

      return false;
    } catch (e) {
      // Connection/API error।
      print("Start trip backend error: $e");

      return false;
    }
  }

  Future<bool> startTracking(
      String busId,
      Function(Position) onLocationUpdate,
      ) async {
    if (isTracking) return true;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return false;

    int parsedBusId = 1; // Default ID if parse fails
    
    // Extracting numeric ID from string like "Bus #104" or "Route A"
    final idMatch = RegExp(r'\d+').firstMatch(busId);
    if (idMatch != null) {
      parsedBusId = int.parse(idMatch.group(0)!);
    }

    // backend expects a valid bus_id and route_id from DB.
    // For now, using parsed ID as both for testing.
    final tripStarted = await startTrip(parsedBusId, 1);

    if (!tripStarted) {
      isTracking = false;
      return false;
    }

    isTracking = true;
    late final LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high, // High accuracy GPS ব্যবহার করে।
        distanceFilter: 10, // 10 meter movement হলে নতুন location নেয়।
        forceLocationManager: true, // Android location manager ব্যবহার করে।
        intervalDuration: const Duration(seconds: 5), // প্রায় 5 second পরপর update নেয়।
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "DUET Smart Bus Tracker", // Background notification title।
          notificationText:
          "Live GPS location streaming active in background...", // Background tracking message।
          notificationIcon: AndroidResource(
            name: 'launcher_icon', // App notification icon।
            defType: 'mipmap', // Icon resource type।
          ),
          enableWakeLock: true, // Device sleep কমাতে সাহায্য করে।
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high, // iOS/other platform-এ high accuracy।
        distanceFilter: 10, // 10 meter movement হলে update নেয়।
      );
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
              (Position position) {
            onLocationUpdate(position);
            _sendLocationToBackend(
              parsedBusId,
              position,
            );
          },
        );

    return true;
  }

  Future<void> _sendLocationToBackend(
      int busId,
      Position position,
      ) async {
    if (AuthService.useRealBackend) {
      try {
        final url = Uri.parse(
          "${AuthService.baseUrl}/api/v1/driver/location",
        ); // Backend-এর GPS location API URL।
        print(
          "DRIVER TRIP ID: $currentTripId",
        );
        print(
          "SENDING GPS: ${position.latitude}, ${position.longitude}",
        ); // Console-এ GPS location দেখায়।
        print("SPEED: ${position.speed}");
        print("HEADING: ${position.heading}");

        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json", // JSON data পাঠায়।
            if (AuthService.bearerToken != null)
              "Authorization": "Bearer ${AuthService.bearerToken}", // Bearer token পাঠায়।
          },
          body: jsonEncode({
            "bus_id": busId,
            "trip_id": currentTripId,
            "lat": position.latitude,
            "lng": position.longitude,
            "speed_kmh": position.speed * 3.6,
            "heading": position.heading,
          }),
        );

        print(
          "GPS STATUS: ${response.statusCode}",
        ); // Backend response status দেখায়।

        if (response.statusCode != 200) {
          print(
            "GPS RESPONSE: ${response.body}",
          ); // Error হলে backend response দেখায়।
        }
      } catch (e) {
        print(
          "Telemetry location backend error: $e",
        ); // Location API error দেখায়।
      }
    }
  }

  Future<bool> endTrip() async {
    if (!AuthService.useRealBackend) return true;

    if (currentTripId == null || currentTripId!.isEmpty) {
      print("ERROR: No active trip ID.");
      return false;
    }

    try {
      // 👇 এই দুইটা line এখানে add করো
      print("END TRIP TOKEN = ${AuthService.bearerToken}");
      print("END TRIP TOKEN LENGTH = ${AuthService.bearerToken?.length}");
      final url = Uri.parse(
        "${AuthService.baseUrl}/api/v1/driver/trips/end",
      );
      print("ENDING TRIP ID: $currentTripId");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (AuthService.bearerToken != null)
            "Authorization": "Bearer ${AuthService.bearerToken}",
        },
        body: jsonEncode({
          "trip_id": currentTripId,
        }),
      );

      print("END TRIP STATUS: ${response.statusCode}");
      print("END TRIP RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        stopTracking();
        currentTripId = null;
        print("TRIP ENDED SUCCESSFULLY");
        return true;
      }

      return false;
    } catch (e) {
      print("End trip backend error: $e");
      return false;
    }
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel(); // GPS stream বন্ধ করে।
    isTracking = false; // Tracking বন্ধ হিসেবে set করে।
  }
}