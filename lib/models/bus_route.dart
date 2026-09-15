import 'package:google_maps_flutter/google_maps_flutter.dart';

enum BusType { student, teacher, micro }

class BusRoute {
  final String id;
  final String name;
  final String code;
  final String stops;
  final String frequency;
  final bool isOnTime;
  final int activeBuses;
  final int totalStops;
  final List<LatLng> polylinePoints;

  BusRoute({
    required this.id,
    required this.name,
    required this.code,
    required this.stops,
    required this.frequency,
    required this.isOnTime,
    required this.activeBuses,
    required this.totalStops,
    this.polylinePoints = const [],
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id']?.toString() ?? '1',
      name: json['name'] ?? 'DUET Route',
      code: json['code'] ?? 'DUET',
      stops: json['description'] ?? 'Campus Loop Stops',
      frequency: "Every 10 mins",
      isOnTime: json['is_active'] ?? true,
      activeBuses: 4,
      totalStops: (json['stop_ids'] as List?)?.length ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "code": code,
      "description": stops,
      "is_active": isOnTime,
    };
  }
}

class BusLocation {
  final String tripId;
  final String busId;
  final String routeCode;
  final LatLng position;
  final double heading;
  final int occupancy;
  final int availableSeats;
  final String eta;
  final BusType type;

  BusLocation({
    required this.tripId,
    required this.busId,
    required this.routeCode,
    required this.position,
    required this.heading,
    required this.occupancy,
    required this.availableSeats,
    required this.eta,
    this.type = BusType.student,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    BusType parseType(String? typeStr) {
      switch (typeStr?.toLowerCase()) {
        case 'teacher':
          return BusType.teacher;
        case 'micro':
          return BusType.micro;
        default:
          return BusType.student;
      }
    }

    final location = json['current_location'] ?? {};

    return BusLocation(
      tripId: json['trip_id']?.toString() ?? '',
      busId: json['bus_id']?.toString() ?? json['bus_name']?.toString() ?? '1',
      routeCode: json['route_name']?.toString() ?? 'A',
      position: LatLng(
        (location['latitude'] ?? 24.0176).toDouble(),
        (location['longitude'] ?? 90.4196).toDouble(),
      ),
      heading: 0.0,
      occupancy: 0,
      availableSeats: 0,
      eta: "Live",
      type: parseType(json['type']),
    );
  }
}

class LocationSharePayload {
  final int busId;
  final String tripId;
  final double lat;
  final double lng;
  final double speedKmh;
  final double heading;

  LocationSharePayload({
    required this.busId,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.heading,
  });

  Map<String, dynamic> toJson() {
    return {
      "bus_id": busId,
      "trip_id": tripId,
      "lat": lat,
      "lng": lng,
      "speed_kmh": speedKmh,
      "heading": heading,
    };
  }
}

class BusPayload {
  final String name;
  final String registrationNumber;
  final int capacity;
  final int routeId;
  final bool isActive;

  BusPayload({
    required this.name,
    required this.registrationNumber,
    required this.capacity,
    required this.routeId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "registration_number": registrationNumber,
      "capacity": capacity,
      "route_id": routeId,
      "is_active": isActive,
    };
  }

  factory BusPayload.fromJson(Map<String, dynamic> json) {
    return BusPayload(
      name: json['name'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      capacity: json['capacity'] ?? 40,
      routeId: json['route_id'] ?? 1,
      isActive: json['is_active'] ?? true,
    );
  }
}

class BusAlert {
  final String title;
  final String description;
  final String time;
  final bool isWarning;

  BusAlert({
    required this.title,
    required this.description,
    required this.time,
    required this.isWarning,
  });
}
