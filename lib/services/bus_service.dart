import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:duet_smart_bus_tracker/models/bus_route.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';

class BusService {
  // Mock data for routes
  static List<BusRoute> getMockRoutes() {
    return [
      BusRoute(
        id: "1",
        name: "North Campus Express",
        code: "A",
        stops: "Central Hub • Science Block • Research Lab",
        frequency: "Every 10 mins",
        isOnTime: true,
        activeBuses: 4,
        totalStops: 12,
      ),
      BusRoute(
        id: "2",
        name: "Dormitory Loop",
        code: "B",
        stops: "West Wing • Dining Hall • Main Gate",
        frequency: "Every 20 mins",
        isOnTime: false,
        activeBuses: 2,
        totalStops: 8,
      ),
      BusRoute(
        id: "3",
        name: "Athletics Center Direct",
        code: "C",
        stops: "Gymnasium • Stadium • Student Union",
        frequency: "Every 15 mins",
        isOnTime: true,
        activeBuses: 3,
        totalStops: 6,
      ),
    ];
  }

  // Mock data for bus locations
  static List<BusLocation> getMockBusLocations() {
    return [
      BusLocation(
        tripId: "mock-trip-1",
        busId: "402",
        routeCode: "A",
        position: const LatLng(24.0176, 90.4196),
        heading: 45,
        occupancy: 60,
        availableSeats: 12,
        eta: "4 mins",
        type: BusType.student,
      ),
      BusLocation(
        tripId: "mock-trip-2",
        busId: "T-05",
        routeCode: "B",
        position: const LatLng(24.0190, 90.4180),
        heading: 180,
        occupancy: 30,
        availableSeats: 25,
        eta: "8 mins",
        type: BusType.teacher,
      ),
      BusLocation(
        tripId: "mock-trip-3",
        busId: "M-12",
        routeCode: "C",
        position: const LatLng(24.0205, 90.4210),
        heading: 270,
        occupancy: 80,
        availableSeats: 2,
        eta: "2 mins",
        type: BusType.micro,
      ),
    ];
  }

  // Mock data for alerts
  static List<BusAlert> getMockAlerts() {
    return [
      BusAlert(
        title: "Route A Delay",
        description: "Heavy traffic on Main St. Expect 10-15 min delay.",
        time: "2 mins ago",
        isWarning: true,
      ),
      BusAlert(
        title: "New Night Service",
        description: "Starting Monday, Route C will run until 1 AM.",
        time: "1 hour ago",
        isWarning: false,
      ),
    ];
  }

  // API Client Methods mapping Postman Collection endpoints
  static Future<List<BusRoute>> fetchAdminRoutes() async {
    if (AuthService.useRealBackend) {
      try {
        final url = Uri.parse("${AuthService.baseUrl}/api/v1/student/trips");
        final response = await http.get(
          url,
          headers: {
            "Authorization": "Bearer ${AuthService.bearerToken}",
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List list = data['data'];
          return list.map((item) => BusRoute.fromJson(item)).toList();
        }
      } catch (e) {
        print("Fetch routes error: $e");
      }
    }
    return getMockRoutes();
  }

static Future<List<BusLocation>> fetchStudentActiveTrips() async {
  // Backend API URL তৈরি করা হচ্ছে
  final url = Uri.parse("${AuthService.baseUrl}/api/v1/student/trips");

  print("FETCHING TRIPS WITH TOKEN: ${AuthService.bearerToken?.substring(0, 10)}...");

  try {
    // Backend-এ GET request পাঠানো হচ্ছে
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (AuthService.bearerToken != null)
          "Authorization": "Bearer ${AuthService.bearerToken}",
      },
    );

    print("FETCH TRIPS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      
      // সর্টিং লজিক
      list.sort((a, b) => (b['started_at'] ?? "").compareTo(a['started_at'] ?? ""));

      return list.map((item) => BusLocation.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized: Please login again.");
    } else {
      throw Exception("Failed to load trips: ${response.statusCode}");
    }
  } catch (e) {
    print("API Error: $e");
    throw Exception("Network or Server error: $e");
  }
}
}