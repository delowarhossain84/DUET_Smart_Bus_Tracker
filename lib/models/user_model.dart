import 'package:duet_smart_bus_tracker/models/bus_route.dart';

enum UserRole { student, teacher, driver, admin }

enum RequestStatus { pending, approved, rejected }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? dob;
  final String? gender;
  final String? address;
  final String? licenseNumber;
  final String? licenseExpiry;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? assignedBus;
  final String? department;
  final String? semester;
  final String? studentId;
  final RequestStatus status;
  final String? accessToken;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.dob,
    this.gender,
    this.address,
    this.licenseNumber,
    this.licenseExpiry,
    this.emergencyName,
    this.emergencyPhone,
    this.assignedBus,
    this.department,
    this.semester,
    this.studentId,
    this.status = RequestStatus.approved,
    this.accessToken,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.student;
    final roleStr = (json['role'] ?? '').toString().toLowerCase();
    if (roleStr == 'driver') {
      parsedRole = UserRole.driver;
    } else if (roleStr == 'admin') {
      parsedRole = UserRole.admin;
    }

    // Backend uses 'mobile', 'dob', 'full_name', etc.
    return AppUser(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: parsedRole,
      fullName: json['full_name'],
      phone: json['mobile'] ?? json['phone'],
      dob: json['dob'],
      gender: json['gender'],
      address: json['address'],
      licenseNumber: json['license_plate'] ?? json['license_number'],
      licenseExpiry: json['license_plate_expiry'],
      emergencyName: json['emergency_contact_name'],
      emergencyPhone: json['emergency_contact_phone'],
      assignedBus: json['assigned_bus'],
      department: json['department'],
      semester: json['current_semester']?.toString(),
      studentId: json['student_id'],
      status: json['status'] == 'active' || json['is_active'] == true 
          ? RequestStatus.approved 
          : RequestStatus.pending,
      accessToken: json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'full_name': fullName,
      'mobile': phone,
      'dob': dob,
      'gender': gender,
      'address': address,
      'license_plate': licenseNumber,
      'license_plate_expiry': licenseExpiry,
      'emergency_contact_name': emergencyName,
      'emergency_contact_phone': emergencyPhone,
      'assigned_bus': assignedBus,
      'department': department,
      'current_semester': semester,
      'student_id': studentId,
      'is_active': status == RequestStatus.approved,
      if (accessToken != null) 'access_token': accessToken,
    };
  }
}

class StudentRegistrationPayload {
  final String name;
  final String email;
  final String password;
  final String mobile;
  final String dob;
  final String gender;
  final String fullName;
  final String role;
  final String address;
  final String studentId;
  final String currentSemester;

  StudentRegistrationPayload({
    required this.name,
    required this.email,
    required this.password,
    required this.mobile,
    required this.dob,
    required this.gender,
    required this.fullName,
    this.role = "student",
    required this.address,
    required this.studentId,
    required this.currentSemester,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "password": password,
      "mobile": mobile,
      "dob": dob,
      "gender": gender,
      "full_name": fullName,
      "role": role,
      "address": address,
      "student_id": studentId,
      "current_semester": currentSemester,
    };
  }
}

class AdminRegistrationPayload {
  final String name;
  final String email;
  final String password;
  final String mobile;
  final String dob;
  final String gender;
  final String fullName;
  final String role;

  AdminRegistrationPayload({
    required this.name,
    required this.email,
    required this.password,
    required this.mobile,
    required this.dob,
    required this.gender,
    required this.fullName,
    this.role = "admin",
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "password": password,
      "mobile": mobile,
      "dob": dob,
      "gender": gender,
      "full_name": fullName,
      "role": role,
    };
  }
}

class DriverRegistrationPayload {
  final String name;
  final String email;
  final String password;
  final String mobile;
  final String dob;
  final String gender;
  final String fullName;
  final String role;
  final String address;
  final String licensePlate;
  final String licensePlateExpiry;
  final String emergencyContactName;
  final String emergencyContactPhone;

  DriverRegistrationPayload({
    required this.name,
    required this.email,
    required this.password,
    required this.mobile,
    required this.dob,
    required this.gender,
    required this.fullName,
    this.role = "driver",
    required this.address,
    required this.licensePlate,
    required this.licensePlateExpiry,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "password": password,
      "mobile": mobile,
      "dob": dob,
      "gender": gender,
      "full_name": fullName,
      "role": role,
      "address": address,
      "license_plate": licensePlate,
      "license_plate_expiry": licensePlateExpiry,
      "emergency_contact_name": emergencyContactName,
      "emergency_contact_phone": emergencyContactPhone,
    };
  }
}

class DriverRequest {
  final String id;
  final String driverName;
  final String email;
  final String phone;
  final String licenseNumber;
  final String requestedBus;
  final String credentialsInfo;
  RequestStatus status;
  bool isOnline;
  final DateTime submittedAt;

  DriverRequest({
    required this.id,
    required this.driverName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.requestedBus,
    this.credentialsInfo = "CDL-B • Air Brakes (Valid 2026)",
    this.status = RequestStatus.pending,
    this.isOnline = false,
    required this.submittedAt,
  });

  factory DriverRequest.fromJson(Map<String, dynamic> json) {
    // Backend sends status: "active", "inactive", "blocked", "pending", etc.
    final String statusStr = (json['status'] ?? '').toString().toLowerCase();
    RequestStatus parsedStatus = RequestStatus.pending;
    
    if (statusStr == 'active') {
      parsedStatus = RequestStatus.approved;
    } else if (statusStr == 'rejected' || statusStr == 'blocked') {
      parsedStatus = RequestStatus.rejected;
    }

    return DriverRequest(
      id: json['id']?.toString() ?? '',
      driverName: json['full_name'] ?? json['username'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['emergency_contact_phone'] ?? json['mobile'] ?? json['phone'] ?? '',
      licenseNumber: json['license_plate'] ?? json['license_number'] ?? '',
      requestedBus: json['assigned_bus'] ?? 'Unassigned',
      credentialsInfo: "License: ${json['license_plate'] ?? 'N/A'}",
      status: parsedStatus,
      isOnline: json['current_status'] == 'running' || json['is_online'] == true,
      submittedAt: DateTime.now(),
    );
  }
}

class DispatchTrip {
  final String tripId;
  final String routeName;
  final String busId;
  final int occupancyCurrent;
  final int occupancyMax;
  final String driverName;
  final String driverInitials;
  final String startTime;
  final String etaMessage;
  final int studentsTrackingCount;
  String status;
  final BusType type;

  DispatchTrip({
    required this.tripId,
    required this.routeName,
    required this.busId,
    required this.occupancyCurrent,
    required this.occupancyMax,
    required this.driverName,
    required this.driverInitials,
    required this.startTime,
    required this.etaMessage,
    required this.studentsTrackingCount,
    required this.status,
    this.type = BusType.student,
  });

  factory DispatchTrip.fromJson(Map<String, dynamic> json) {
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

    return DispatchTrip(
      tripId: json['trip_id'] ?? json['id']?.toString() ?? '#TRP-000',
      routeName: json['route_name'] ?? json['route'] ?? 'Campus Express',
      busId: "Bus #${json['bus_id'] ?? '104'}",
      occupancyCurrent: json['occupancy_current'] ?? 28,
      occupancyMax: json['occupancy_max'] ?? 44,
      driverName: json['driver_name'] ?? 'Driver',
      driverInitials: (json['driver_name'] ?? 'D').toString().substring(0, 1).toUpperCase(),
      startTime: json['start_time'] ?? '08:15 AM',
      etaMessage: json['eta_message'] ?? 'On-Time',
      studentsTrackingCount: json['students_tracking'] ?? 42,
      status: json['status'] ?? 'Running',
      type: parseType(json['type']),
    );
  }

  double get occupancyRatio => occupancyMax > 0 ? occupancyCurrent / occupancyMax : 0.0;
  int get occupancyPercentage => (occupancyRatio * 100).round();
}

class CampusStopCard {
  final String stopId;
  final String stopCode;
  final String name;
  final String locationSubtext;
  final List<String> routes;
  final int studentQueueCount;
  final String estWaitTime;
  final double? latitude;
  final double? longitude;

  CampusStopCard({
    required this.stopId,
    required this.stopCode,
    required this.name,
    required this.locationSubtext,
    required this.routes,
    required this.studentQueueCount,
    required this.estWaitTime,
    this.latitude,
    this.longitude,
  });

  factory CampusStopCard.fromJson(Map<String, dynamic> json) {
    return CampusStopCard(
      stopId: json['id']?.toString() ?? '',
      stopCode: "#STP-${json['id'] ?? '01'}",
      name: json['name'] ?? 'Bus Stop',
      locationSubtext: "Lat: ${json['lattitude'] ?? json['latitude']}, Lng: ${json['longitude']}",
      routes: ["Blue Line", "North Shuttle"],
      studentQueueCount: 18,
      estWaitTime: "~3 min wait",
      latitude: (json['lattitude'] ?? json['latitude'])?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "lattitude": latitude ?? 23.70,
      "longitude": longitude ?? 90.30,
    };
  }
}
