import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:duet_smart_bus_tracker/models/bus_route.dart';
import 'package:duet_smart_bus_tracker/services/driver_service.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';
import 'package:duet_smart_bus_tracker/login_screen.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final DriverService _driverService = DriverService();
  Position? _currentPosition;
  bool _isOnline = false;
  bool _isLoading = true; // Start loading

  List<BusRoute> _routes = [];
  List<BusPayload> _buses = [];
  BusRoute? _selectedRoute;
  BusPayload? _selectedBus;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final routesFuture = DriverService.fetchDriverRoutes();
    final busesFuture = DriverService.fetchDriverBuses();

    final results = await Future.wait([routesFuture, busesFuture]);
    var fetchedRoutes = results[0] as List<BusRoute>;
    final fetchedBuses = results[1] as List<BusPayload>;

    // Fallback: If no routes returned from backend route list, but buses exist, derive routes from buses
    if (fetchedRoutes.isEmpty && fetchedBuses.isNotEmpty) {
      final derivedRoutes = <BusRoute>[];
      for (final bus in fetchedBuses) {
        final routeId = bus.routeId;
        if (!derivedRoutes.any((r) => r.id == routeId.toString())) {
          derivedRoutes.add(
            BusRoute(
              id: routeId.toString(),
              name: "Route $routeId",
              code: "R$routeId",
              stops: "Assigned Bus Route",
              frequency: "Every 10 mins",
              isOnTime: true,
              activeBuses: 1,
              totalStops: 0,
            ),
          );
        }
      }
      fetchedRoutes = derivedRoutes;
    }

    if (mounted) {
      setState(() {
        _routes = fetchedRoutes;
        _buses = fetchedBuses;

        if (_routes.isNotEmpty) {
          _selectedRoute = _routes.first;
        }

        if (_buses.isNotEmpty) {
          _selectedBus = _buses.first;
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _toggleShift() async {
    if (_selectedRoute == null || _selectedBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a route and a bus first.")),
      );
      return;
    }

    if (_isOnline) {
      setState(() => _isLoading = true);
      final success = await _driverService.endTrip();
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _isOnline = false;
          _currentPosition = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shift ended successfully."), backgroundColor: Colors.blue),
        );
      } else {
        _showForceStopDialog();
      }
    } else {
      setState(() => _isLoading = true);
      
      final busId = int.tryParse(_selectedBus!.registrationNumber) ?? 1; // ID is stored here
      final routeId = int.tryParse(_selectedRoute!.id) ?? 1;

      final success = await _driverService.startTracking(busId, routeId, (position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
        });
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _isOnline = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shift started! Broadcasting live..."), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to start shift. Ensure Route/Bus exists in Backend."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendQuickAlert(String alertMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Broadcast sent: '$alertMessage'"),
        backgroundColor: const Color(0xFF003366),
      ),
    );
  }

  void _showForceStopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Backend Error"),
        content: const Text("Could not end trip on server. This usually happens if Trip ID is missing or server has a bug. Do you want to force stop locally?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _driverService.stopTracking();
              setState(() {
                _isOnline = false;
                _currentPosition = null;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Force Stop Locally"),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    if (_isOnline) {
      _driverService.stopTracking();
    }

    await AuthService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),

      appBar: AppBar(
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFFBA1A1A),
            ),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              const SizedBox(height: 10),

              if (_routes.isEmpty && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red.withValues(alpha: 0.1),
                  child: const Text("No routes or buses found. Admin needs to create them first.", style: TextStyle(color: Colors.red)),
                ),

              // Route Selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("Select Active Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E2EA))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BusRoute>(
                    value: _selectedRoute,
                    isExpanded: true,
                    hint: const Text("Select Route"),
                    onChanged: _isOnline ? null : (BusRoute? newValue) {
                      setState(() {
                        _selectedRoute = newValue;
                      });
                    },
                    items: _routes.map<DropdownMenuItem<BusRoute>>((BusRoute value) {
                      return DropdownMenuItem<BusRoute>(
                        value: value,
                        child: Text("${value.name} (${value.code})", style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bus Selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("Select Active Bus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E2EA))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BusPayload>(
                    value: _selectedBus,
                    isExpanded: true,
                    hint: const Text("Select Bus"),
                    onChanged: _isOnline ? null : (BusPayload? newValue) {
                      setState(() {
                        _selectedBus = newValue;
                      });
                    },
                    items: _buses.map<DropdownMenuItem<BusPayload>>((BusPayload value) {
                      return DropdownMenuItem<BusPayload>(
                        value: value,
                        child: Text(value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                decoration: BoxDecoration(
                  color: _isOnline
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFFFDAD6),

                  borderRadius: BorderRadius.circular(30),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Container(
                      width: 10,
                      height: 10,

                      decoration: BoxDecoration(
                        color: _isOnline
                            ? Colors.green
                            : Colors.red,

                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      _isOnline
                          ? "LIVE STREAMING"
                          : "OFFLINE",

                      style: TextStyle(
                        fontWeight: FontWeight.bold,

                        color: _isOnline
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick One-Tap Preset Delay & Weather Alert Buttons
              if (_isOnline) ...[
                const Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    "One-Tap Live Broadcast Alerts",

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _buildPresetButton(
                      "Traffic +5m",
                      Icons.traffic,
                      Colors.orange[800]!,
                    ),

                    const SizedBox(width: 8),

                    _buildPresetButton(
                      "Heavy Rain",
                      Icons.thunderstorm,
                      Colors.blue[800]!,
                    ),

                    const SizedBox(width: 8),

                    _buildPresetButton(
                      "Short Break",
                      Icons.free_breakfast,
                      Colors.purple[800]!,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],

              // GPS Information
              if (_currentPosition != null) ...[
                // Active Trip ID
                if (_isOnline &&
                    _driverService.currentTripId != null)
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      border: Border.all(
                        color: const Color(0xFFE1E2EA),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Active Trip ID",

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _driverService.currentTripId!,

                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // GPS Card
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(24),

                    border: Border.all(
                      color: const Color(0xFFE1E2EA),
                    ),
                  ),

                  child: Column(
                    children: [
                      _buildInfoRow(
                        "Latitude",
                        _currentPosition!.latitude
                            .toStringAsFixed(6),
                      ),

                      const Divider(height: 30),

                      _buildInfoRow(
                        "Longitude",
                        _currentPosition!.longitude
                            .toStringAsFixed(6),
                      ),

                      const Divider(height: 30),

                      _buildInfoRow(
                        "Speed",
                        "${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h",
                      ),

                      const Divider(height: 30),

                      _buildInfoRow(
                        "Heading",
                        "${_currentPosition!.heading.toStringAsFixed(1)}°",
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Start/Stop Button
              SizedBox(
                width: double.infinity,
                height: 70,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleShift,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOnline
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF1565C0),

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    elevation: 0,
                  ),

                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isOnline
                        ? "STOP SHIFT"
                        : "START SHIFT",

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Keep the app open and phone charged during your shift.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF727783),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(
      String label,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: InkWell(
        onTap: () => _sendQuickAlert(label),

        borderRadius: BorderRadius.circular(16),

        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),

          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),

            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),

          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),

              const SizedBox(height: 6),

              Text(
                label,

                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

      children: [
        Text(
          label,

          style: const TextStyle(
            color: Color(0xFF424752),
          ),
        ),

        Text(
          value,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _driverService.stopTracking();

    super.dispose();
  }
}