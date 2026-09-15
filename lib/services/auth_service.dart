import 'dart:convert'; // JSON encode/decode করার জন্য ব্যবহার করা হয়েছে।
import 'package:http/http.dart' as http; // Backend API-তে HTTP request পাঠানোর জন্য ব্যবহার করা হয়েছে।
import 'package:shared_preferences/shared_preferences.dart'; // Local storage-এর জন্য।
import 'package:duet_smart_bus_tracker/models/user_model.dart'; // AppUser এবং UserRole model ব্যবহার করার জন্য import করা হয়েছে।
import 'package:duet_smart_bus_tracker/models/bus_route.dart'; // Bus এবং route related model ব্যবহার করার জন্য import করা হয়েছে।

enum AuthStatus { success, pendingApproval, rejected, invalidCredentials } // Login/register result বোঝানোর জন্য status তৈরি করা হয়েছে।

class AuthResponse { // Authentication response রাখার জন্য class তৈরি করা হয়েছে।
  final AuthStatus status; // Authentication-এর status সংরক্ষণ করে।
  final String? message; // Optional message সংরক্ষণ করে।
  final AppUser? user; // Login হলে user information সংরক্ষণ করে।

  AuthResponse({required this.status, this.message, this.user}); // AuthResponse তৈরি করার constructor।
}

class AuthService { // Authentication এবং backend related কাজ রাখার service class।
  static bool useRealBackend = true; // false হওয়ায় এখন mock data ব্যবহার হবে।

  static const String baseUrl = "https://duet-bus-tracker.onrender.com"; // Physical phone থেকে PC backend access করার IP address।
  static String? bearerToken; // Backend থেকে পাওয়া access token এখানে রাখা হবে।

  static List<DriverRequest> _driverRequests = [];
  static List<DispatchTrip> _dispatchTrips = [];
  static List<CampusStopCard> _campusStops = [];
  static List<BusRoute> _routes = []; // নতুন যোগ করা হয়েছে
  static Map<String, dynamic> _stats = {};
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadSession();
  }

  static Future<void> saveSession(AppUser user, String token) async {
    if (_prefs == null) return;
    await _prefs!.setString('bearerToken', token);
    await _prefs!.setString('userData', jsonEncode(user.toJson()));
  }

  static Future<void> loadSession() async {
    if (_prefs == null) return;
    bearerToken = _prefs!.getString('bearerToken');
    final userData = _prefs!.getString('userData');
    if (userData != null) {
      currentUser = AppUser.fromJson(jsonDecode(userData));
    }
  }

  static Future<void> clearSession() async {
    if (_prefs == null) return;
    await _prefs!.remove('bearerToken');
    await _prefs!.remove('userData');
    currentUser = null;
    bearerToken = null;
  }

  static final List<AppUser> _users = [
    AppUser(
      id: "u_admin",
      name: "Sarah Jenkins",
      email: "admin@duet.ac.bd",
      role: UserRole.admin,
    ),
    AppUser(
      id: "u_student",
      name: "DUET Student",
      email: "student@duet.ac.bd",
      role: UserRole.student,
      department: "CSE",
      semester: "4th Semester",
    ),
    AppUser(
      id: "u_delowar",
      name: "delowar",
      fullName: "Delowar Hossain",
      email: "delowar20@gmail.com",
      role: UserRole.student,
      department: "CSE",
      semester: "32",
      studentId: "2204084",
      dob: "2003-08-30",
      gender: "Male",
      address: "Duet, Gazipur",
      phone: "01738976919",
    ),
  ];

  static AppUser? currentUser;

  static Future<AuthResponse> login(
      String email,
      String password,
      UserRole selectedRole,
      ) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (useRealBackend) {
      try {
        final url = Uri.parse("$baseUrl/api/v1/auth/login");

        final request = http.MultipartRequest("POST", url)
          ..fields['username'] = trimmedEmail
          ..fields['password'] = password;

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print("LOGIN STATUS: ${response.statusCode}");
        print("LOGIN BODY: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          bearerToken = data['access_token'];
          
          final user = AppUser(
            id: "u_${DateTime.now().millisecondsSinceEpoch}",
            name: trimmedEmail.split('@')[0],
            email: trimmedEmail,
            role: selectedRole,
            accessToken: bearerToken,
          );

          currentUser = user;
          await saveSession(user, bearerToken!);
          return AuthResponse(status: AuthStatus.success, user: user);
        } else {
          return AuthResponse(
            status: AuthStatus.invalidCredentials,
            message: "Invalid credentials from backend server.",
          );
        }
      } catch (e) {
        return AuthResponse(
          status: AuthStatus.invalidCredentials,
          message: "Backend connection error: $e",
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (trimmedEmail.isEmpty || password.isEmpty) {
      return AuthResponse(
        status: AuthStatus.invalidCredentials,
        message: "Please enter both email and password.",
      );
    }

    if (selectedRole == UserRole.driver) {
      final existingReq = _driverRequests.firstWhere(
            (req) => req.email.toLowerCase() == trimmedEmail,
        orElse: () => DriverRequest(
          id: "",
          driverName: "",
          email: "",
          phone: "",
          licenseNumber: "",
          requestedBus: "",
          submittedAt: DateTime.now(),
        ),
      );

      if (existingReq.id.isNotEmpty && existingReq.status == RequestStatus.pending) {
        return AuthResponse(
          status: AuthStatus.pendingApproval,
          message: "Your driver registration is pending admin approval.",
        );
      }

      final driverUser = AppUser(
        id: "driver_1",
        name: existingReq.driverName.isNotEmpty ? existingReq.driverName : "Campus Driver",
        fullName: existingReq.driverName,
        email: trimmedEmail,
        role: UserRole.driver,
        assignedBus: "Bus #104",
      );

      currentUser = driverUser;
      return AuthResponse(status: AuthStatus.success, user: driverUser);
    }

    final existingUser = _users.firstWhere(
          (u) => u.email.toLowerCase() == trimmedEmail,
      orElse: () => AppUser(id: "", name: "", email: "", role: UserRole.student),
    );

    if (existingUser.id.isNotEmpty) {
      currentUser = existingUser;
      return AuthResponse(status: AuthStatus.success, user: existingUser);
    }

    final appUser = AppUser(
      id: "u_1",
      name: selectedRole == UserRole.teacher ? "DUET Teacher" : "DUET Student",
      email: trimmedEmail,
      role: selectedRole,
      department: "CSE",
      semester: selectedRole == UserRole.student ? "4th Semester" : null,
    );

    currentUser = appUser;
    return AuthResponse(status: AuthStatus.success, user: appUser);
  }

  static Future<AuthResponse> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String fullName,
    required String phone,
    required String dob,
    required String gender,
    required String address,
    String? studentId,
    String? semester,
    String? licenseNumber,
    String? licenseExpiry,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? preferredBus,
    String? department,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (useRealBackend) {
      try {
        if (role == UserRole.driver) {
          final url = Uri.parse("$baseUrl/api/v1/users/register/driver");

          final payload = DriverRegistrationPayload(
            name: name,
            email: trimmedEmail,
            password: password,
            mobile: phone,
            dob: dob,
            gender: gender,
            fullName: fullName,
            address: address,
            licensePlate: licenseNumber ?? "0000",
            licensePlateExpiry: licenseExpiry ?? "2026-01-01",
            emergencyContactName: emergencyContactName ?? "Emergency",
            emergencyContactPhone: emergencyContactPhone ?? phone,
          );

          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload.toJson()),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            return AuthResponse(
              status: AuthStatus.pendingApproval,
              message: "Driver application submitted to backend server!",
            );
          }
        } else {
          final url = Uri.parse("$baseUrl/api/v1/users/register/student");

          final payload = StudentRegistrationPayload(
            name: name,
            email: trimmedEmail,
            password: password,
            mobile: phone,
            dob: dob,
            gender: gender,
            fullName: fullName,
            address: address,
            studentId: studentId ?? "0000000",
            currentSemester: semester ?? "1st Semester",
          );

          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload.toJson()),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final user = AppUser(
              id: "user_${DateTime.now().millisecondsSinceEpoch}",
              name: name,
              email: trimmedEmail,
              role: UserRole.student,
              fullName: fullName,
              phone: phone,
              dob: dob,
              gender: gender,
              address: address,
              studentId: studentId,
              department: department,
              semester: semester,
            );

            currentUser = user;
            await saveSession(user, ""); // Registration directly logs in student but token comes from login usually
            return AuthResponse(status: AuthStatus.success, user: user);
          }
        }
      } catch (e) {
        print("Backend register error: $e");
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (role == UserRole.driver) {
      final newRequest = DriverRequest(
        id: "req_${DateTime.now().millisecondsSinceEpoch}",
        driverName: fullName,
        email: trimmedEmail,
        phone: phone,
        licenseNumber: licenseNumber ?? "CDL-PENDING",
        requestedBus: preferredBus ?? "Bus #412",
        status: RequestStatus.pending,
        submittedAt: DateTime.now(),
      );

      _driverRequests.insert(0, newRequest);

      return AuthResponse(
        status: AuthStatus.pendingApproval,
        message: "Registration submitted! Please wait for Admin approval before logging in.",
      );
    }

    final newUser = AppUser(
      id: "user_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      email: trimmedEmail,
      role: UserRole.student,
      fullName: fullName,
      phone: phone,
      dob: dob,
      gender: gender,
      address: address,
      studentId: studentId,
      department: department ?? "CSE",
      semester: semester ?? "1st Semester",
    );

    _users.add(newUser);
    currentUser = newUser;
    return AuthResponse(status: AuthStatus.success, user: newUser);
  }

  static Future<void> fetchDashboardData() async {
    if (!useRealBackend || bearerToken == null) return;

    try {
      final url = Uri.parse("$baseUrl/api/v1/admin/dashboard");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $bearerToken"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dashboard = data['data'];

        if (dashboard['trips'] != null) {
          final List tripsList = dashboard['trips']['data'] ?? [];
          _dispatchTrips = tripsList.map((t) => DispatchTrip.fromJson(t)).toList();
        }

        // Map drivers
        if (dashboard['drivers'] != null) {
          final List driversList = dashboard['drivers']['data'] ?? [];
          _driverRequests = driversList.map((d) => DriverRequest.fromJson(d)).toList();
        }

        // Map routes
        if (dashboard['routes'] != null) {
          final List routesList = dashboard['routes']['data'] ?? [];
          _routes = routesList.map((r) => BusRoute.fromJson(r)).toList();
        }

        _stats = {
          "studentsLive": dashboard['number_student_tracking'] ?? 0,
          "activeTrips": _dispatchTrips.where((t) => t.status.toLowerCase() == 'running').length,
          "onlineDrivers": _driverRequests.where((d) => d.isOnline).length,
          "pendingRequests": _driverRequests.where((d) => d.status == RequestStatus.pending).length,
          "totalBuses": dashboard['buses']?['total'] ?? 0,
          "totalRoutes": dashboard['routes']?['total'] ?? 0,
        };
      }
    } catch (e) {
      print("Dashboard fetch error: $e");
    }
  }

  static Future<bool> createStop({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    if (!useRealBackend || bearerToken == null) return true;

    try {
      final url = Uri.parse("$baseUrl/api/v1/admin/stops");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $bearerToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "lattitude": latitude, // backend uses double 't'
          "longitude": longitude,
          "is_active": true,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Create stop error: $e");
      return false;
    }
  }

  static Future<bool> createRoute({
    required String name,
    required String code,
    required String description,
  }) async {
    if (!useRealBackend || bearerToken == null) return true;

    try {
      final url = Uri.parse("$baseUrl/api/v1/admin/routes");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $bearerToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "code": code,
          "description": description,
          "is_active": true,
          "stop_ids": [],
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Create route error: $e");
      return false;
    }
  }

  static Future<void> fetchStops() async {
    if (!useRealBackend || bearerToken == null) return;
    try {
      final url = Uri.parse("$baseUrl/api/v1/admin/stops?page=1&per_page=100");
      final response = await http.get(url, headers: {"Authorization": "Bearer $bearerToken"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data']['data'] ?? [];
        _campusStops = list.map((s) => CampusStopCard.fromJson(s)).toList();
      }
    } catch (e) {
      print("Fetch stops error: $e");
    }
  }

  static List<DriverRequest> getDriverRequests() => _driverRequests;
  static List<DispatchTrip> getDispatchTrips() => _dispatchTrips;
  static List<CampusStopCard> getCampusStops() => _campusStops;
  static List<BusRoute> getRoutes() => _routes;
  
  static Map<String, dynamic> getSystemStats() {
    if (useRealBackend && _stats.isNotEmpty) {
       return _stats;
    }
    return {
      "studentsLive": _stats['studentsLive'] ?? 0,
      "activeTrips": _stats['activeTrips'] ?? 0,
      "onlineDrivers": _stats['onlineDrivers'] ?? 0,
      "pendingRequests": _stats['pendingRequests'] ?? 0,
    };
  }

  static Map<String, int> getDepartmentStats() {
    return {
      "Computer Science (CSE)": 420,
      "Electrical (EEE)": 350,
      "Mechanical (ME)": 280,
      "Civil Engineering (CE)": 200,
      "Textile Engineering (TE)": 110,
      "Architecture (Arch)": 60,
    };
  }

  static Future<bool> approveDriverRequest(String requestId) async {
    if (useRealBackend && bearerToken != null) {
      try {
        final response = await http.patch(
          Uri.parse("$baseUrl/api/v1/admin/drivers/$requestId"),
          headers: {
            "Authorization": "Bearer $bearerToken",
            "Content-Type": "application/json",
          },
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        print("Approve error: $e");
      }
      return false;
    }

    final index = _driverRequests.indexWhere((req) => req.id == requestId);
    if (index != -1) {
      _driverRequests[index].status = RequestStatus.approved;
      _driverRequests[index].isOnline = true;
    }
    return true;
  }

  static void startTrip(String tripId) {
    final index = _dispatchTrips.indexWhere((t) => t.tripId == tripId);
    if (index != -1) {
      _dispatchTrips[index].status = "Running";
    }
  }

  static void stopTrip(String tripId) {
    final index = _dispatchTrips.indexWhere((t) => t.tripId == tripId);
    if (index != -1) {
      _dispatchTrips[index].status = "Completed";
    }
  }

  static void dispatchNewTrip({
    required String routeName,
    required String busId,
    required BusType type,
    required String driverName,
  }) {
    final tripId = "#TRP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}";
    final newTrip = DispatchTrip(
      tripId: tripId,
      routeName: routeName,
      busId: busId,
      occupancyCurrent: 0,
      occupancyMax: type == BusType.micro ? 12 : 44,
      driverName: driverName,
      driverInitials: driverName.substring(0, 1).toUpperCase(),
      startTime: "Just now",
      etaMessage: "Live",
      studentsTrackingCount: 0,
      status: "Running",
      type: type,
    );
    _dispatchTrips.insert(0, newTrip);
  }

  static Future<bool> rejectDriverRequest(String requestId) async {
    if (useRealBackend && bearerToken != null) {
      try {
        final response = await http.delete(
          Uri.parse("$baseUrl/api/v1/admin/drivers/$requestId"),
          headers: {"Authorization": "Bearer $bearerToken"},
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      } catch (e) {
        print("Reject error: $e");
      }
      return false;
    }

    final index = _driverRequests.indexWhere((req) => req.id == requestId);
    if (index != -1) {
      _driverRequests[index].status = RequestStatus.rejected;
      _driverRequests[index].isOnline = false;
    }
    return true;
  }

  static Future<void> logout() async {
    await clearSession();
  }
}
