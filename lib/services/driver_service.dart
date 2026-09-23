import 'dart:async'; // Async operation এবং StreamSubscription ব্যবহারের জন্য।
import 'package:flutter/foundation.dart'; // Android platform check করার জন্য।
import 'package:geolocator/geolocator.dart'; // GPS location নেওয়ার জন্য।
import 'package:http/http.dart' as http; // Backend API call করার জন্য।
import 'dart:convert'; // JSON encode/decode করার জন্য।
import 'package:duet_smart_bus_tracker/models/bus_route.dart'; // BusRoute model ব্যবহারের জন্য।
import 'package:duet_smart_bus_tracker/services/auth_service.dart'; // Login token এবং backend URL ব্যবহারের জন্য।

class DriverService {
  StreamSubscription<Position>? _positionStreamSubscription; // GPS stream বন্ধ করার জন্য subscription রাখে।
  bool isTracking = false; // GPS tracking চলছে কিনা রাখে।
  String? currentTripId; // Current trip ID রাখে।

  static Future<List<BusRoute>> fetchDriverRoutes() async {
    if (!AuthService.useRealBackend || AuthService.bearerToken == null) return [];
    try {
      final url = Uri.parse(
          "${AuthService.baseUrl}/api/v1/driver/list-routes?search="
      );
      final response = await http.get(url, headers: {"Authorization": "Bearer ${AuthService.bearerToken}"});
      
      print("DRIVER ROUTES STATUS: ${response.statusCode}");
      print("DRIVER ROUTES BODY: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = [];
        if (data['data'] != null && data['data']['data'] != null) {
          list = data['data']['data'];
        } else if (data['data'] != null && data['data'] is List) {
          list = data['data'];
        }
        print("DRIVER ROUTES FETCHED: ${list.length}");
        return list.map((r) => BusRoute.fromJson(r)).toList();
      } else {
        print("DRIVER ROUTES ERROR: ${response.body}");
      }
    } catch (e) {
      print("Fetch driver routes error: $e");
    }
    return [];
  }

  static Future<List<BusPayload>> fetchDriverBuses() async {
    if (!AuthService.useRealBackend || AuthService.bearerToken == null) return [];
    try {
      final url = Uri.parse(
          "${AuthService.baseUrl}/api/v1/driver/list-buses?search="
      );
      final response = await http.get(url, headers: {"Authorization": "Bearer ${AuthService.bearerToken}"});
      
      print("DRIVER BUSES STATUS: ${response.statusCode}");
      print("DRIVER BUSES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = [];
        if (data['data'] != null && data['data']['data'] != null) {
          list = data['data']['data'];
        } else if (data['data'] != null && data['data'] is List) {
          list = data['data'];
        }
        print("DRIVER BUSES FETCHED: ${list.length}");
        // Temporary mapping since BusPayload is generic enough
        return list.map((b) => BusPayload(
          name: b['name'] ?? '',
          registrationNumber: b['id'].toString(), // Storing ID here temporarily for dropdown
          capacity: b['capacity'] ?? 40,
          routeId: b['route_id'] ?? 1,
        )).toList();
      } else {
        print("DRIVER BUSES ERROR: ${response.body}");
      }

    } catch (e) {
      print("Fetch driver buses error: $e");
    }
    return [];
  }

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
      // Backend-এর trip start API URL.
      final url = Uri.parse(
        "${AuthService.baseUrl}/api/v1/driver/trips/start",
      );

      // Backend-এ trip start request পাঠানো।
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

        if (currentTripId == null || currentTripId!.isEmpty) {
          print("WARNING: Backend did not return Trip ID.");
          print("Trip was started successfully according to backend.");
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
      int busId,
      int routeId,
      Function(Position) onLocationUpdate,
      ) async {
    if (isTracking) return true;

    final hasPermission = await requestPermissions();
    print("DRIVER GPS PERMISSION: $hasPermission");
    if (!hasPermission) return false;

    final tripStarted = await startTrip(busId, routeId);

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
              busId,
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
      final url = Uri.parse(
        "${AuthService.baseUrl}/api/v1/driver/trips/end",
      );

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