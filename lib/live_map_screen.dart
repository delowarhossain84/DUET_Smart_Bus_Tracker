import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';
import 'services/bus_service.dart';
import 'models/bus_route.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'services/auth_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LiveMapScreen extends StatefulWidget {
  final String tripId;

  const LiveMapScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  late GoogleMapController mapController;
  final List<BusLocation> busLocations = [];
  BusLocation? selectedBus;
  WebSocketChannel? _channel;
  Timer? _locationTimer;
  StreamSubscription? _webSocketSubscription;
  LatLng? _livePosition;
  LatLng? _studentPosition;
  String _liveBusId = "1";
  double? _liveSpeed;
  double? _liveEta;
  double _liveHeading = 0;
  BitmapDescriptor? _busIcon;

  static const LatLng duetLocation = LatLng(24.0176, 90.4196);

  Future<BitmapDescriptor> _loadBusIcon() async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(60, 60)),
      'assets/bus.png',
    );
  }

  @override
  void initState() {
    super.initState();

    _loadBusIcon().then((icon) {
      if (mounted) {
        setState(() {
          _busIcon = icon;
        });
      }
    });
    print("LIVE MAP OPENED: ${widget.tripId}");
    selectedBus = BusLocation(
      tripId: widget.tripId,
      busId: "1",
      routeCode: "A-DUET",
      position: duetLocation,
      heading: 0,
      occupancy: 0,
      availableSeats: 0,
      eta: "N/A",
      type: BusType.student,
    );_connectWebSocket();
  }
  void _moveBusSmoothly(LatLng newPosition) {
    // বর্তমান bus position না থাকলে সরাসরি নতুন position সেট করবে।
    if (_livePosition == null) {
      setState(() {
        _livePosition = newPosition;
      });
      return;
    }

    // আগের bus position সংরক্ষণ করবে।
    final oldPosition = _livePosition!;

    // bus কত ধাপে move করবে তা নির্ধারণ করবে।
    const int steps = 20;

    // প্রতিটি ধাপের সংখ্যা রাখবে।
    int step = 0;

    // প্রতি 50 milliseconds পর bus-এর position একটু একটু করে পরিবর্তন করবে।
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // একটি নতুন ধাপ শুরু করবে।
      step++;

      // পুরোনো এবং নতুন position-এর মাঝের অংশ হিসাব করবে।
      final double progress = step / steps;

      // latitude ধীরে ধীরে পরিবর্তন করবে।
      final double lat =
          oldPosition.latitude +
              (newPosition.latitude - oldPosition.latitude) * progress;

      // longitude ধীরে ধীরে পরিবর্তন করবে।
      final double lng =
          oldPosition.longitude +
              (newPosition.longitude - oldPosition.longitude) * progress;

      // নতুন position তৈরি করবে।
      final position = LatLng(lat, lng);

      // Map-এ bus-এর position update করবে।
      if (mounted) {
        setState(() {
          _livePosition = position;

        });
        mapController.animateCamera(
          CameraUpdate.newLatLng(position),
        );
      }

      // নতুন position-এ পৌঁছে গেলে timer বন্ধ করবে।
      if (step >= steps) {
        timer.cancel();
      }
    });
  }

  Future<Position?> _getStudentLocation() async {
    // ফোনে location service চালু আছে কিনা check করবে।
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // Location service বন্ধ থাকলে আর এগোবে না।
    if (!serviceEnabled) {
      print("LOCATION SERVICE IS OFF");
      return null;
    }

    // Location permission-এর বর্তমান status নেবে।
    LocationPermission permission = await Geolocator.checkPermission();

    // Permission এখনও না দিলে permission চাইবে।
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Permission permanently denied হলে location নেওয়া যাবে না।
    if (permission == LocationPermission.deniedForever) {
      print("LOCATION PERMISSION PERMANENTLY DENIED");
      return null;
    }

    // ফোনের বর্তমান GPS location return করবে।
    return await Geolocator.getCurrentPosition();
  }


  void _connectWebSocket() {

    final uri = Uri.parse(
    '${AuthService.baseUrl.replaceFirst("http://", "ws://")}/api/v1/ws/trip/${widget.tripId}'
    );

    debugPrint("WS URL: $uri");
    debugPrint("TRIP ID: ${widget.tripId}");

    _channel = WebSocketChannel.connect(uri);


    debugPrint("CONNECTING WS: ${widget.tripId}");
    _channel!.sink.add(jsonEncode({
      "lat": 24.0176,
      "lng": 90.4196,
    }));
    print("STUDENT LOCATION SENT");
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
          (timer) async {
            final position = await _getStudentLocation();

            if (position != null) {
              setState(() {
                _studentPosition = LatLng(
                  position.latitude,
                  position.longitude,
                );
              });
              _channel?.sink.add(jsonEncode({
                "lat": position.latitude,
                "lng": position.longitude,
              }));

              print("STUDENT GPS AGAIN: ${position.latitude}, ${position.longitude}");
            }

        print("STUDENT LOCATION SENT AGAIN");
      },
    );
    _webSocketSubscription = _channel!.stream.listen(
          (message) {
        print("WEBSOCKET DATA: $message");

        final data = jsonDecode(message);

        if (data['bus_lat'] != null && data['bus_lng'] != null) {
          _liveBusId = data['bus_id'].toString();
          _liveSpeed = double.tryParse(data['bus_speed_kmh'].toString());
          _liveEta = double.tryParse(data['eta_seconds'].toString());
          _liveHeading = double.tryParse(data['bus_heading'].toString()) ?? 0;
          final position = LatLng(
            double.parse(data['bus_lat'].toString()),
            double.parse(data['bus_lng'].toString()),
          );

          _moveBusSmoothly(position);

          setState(() {
            selectedBus = BusLocation(
              tripId: data['trip_id'].toString(),
              busId: data['bus_id'].toString(),
              routeCode: "A",
              position: position,
              heading: _liveHeading,
              occupancy: 0,
              availableSeats: 0,
              eta: _liveEta != null
                  ? "${_liveEta!.round()} sec"
                  : "N/A",
              type: BusType.student,
            );
          });

          print("LIVE POSITION: $_livePosition");
        }
      },
      onError: (error) {
        print("WEBSOCKET ERROR: $error");
      },
      onDone: () {
        print("WEBSOCKET CLOSED");
      },
    );
  }


  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMarkerTapped(BusLocation bus) {
    setState(() {
      selectedBus = bus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Render GoogleMap on native mobile or Interactive Fallback Radar Canvas on Web / No API Key
          if (kIsWeb)
            _buildInteractiveTelemetryRadarMap()
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: duetLocation,
                zoom: 16,
              ),
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                if (_livePosition != null)
                  Marker(
                    markerId: const MarkerId("bus_1"),
                    position: _livePosition!,
                    icon: _busIcon ?? BitmapDescriptor.defaultMarker,
                    rotation: _liveHeading,
                    flat: true,
                    infoWindow: const InfoWindow(
                      title: "Bus #1",
                      snippet: "DUET Route",
                    ),
                  ),

                if (_studentPosition != null)
                  Marker(
                    markerId: const MarkerId("student"),
                    position: _studentPosition!,
                    infoWindow: const InfoWindow(
                      title: "You",
                      snippet: "Your current location",
                    ),
                  ),
              },
            ),

          // Top Header (Floating)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.directions_bus, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Live Tracking Radar",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.search, color: Color(0xFF424752)),
                  ),
                ],
              ),
            ),
          ),

          // Floating Controls
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                _buildMapFab(Icons.layers_outlined),
                const SizedBox(height: 12),
                _buildMapFab(Icons.refresh),
                const SizedBox(height: 12),
                _buildMapFab(Icons.my_location, isPrimary: true),
              ],
            ),
          ),

          // Bottom Detail Sheet
          if (selectedBus != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6E3FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.directions_bus, size: 32, color: Color(0xFF1565C0)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Bus #${selectedBus!.busId}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text("Route ${selectedBus!.routeCode} - DUET Campus Express", style: const TextStyle(color: Color(0xFF424752))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text("ON TIME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                                const SizedBox(height: 4),
                                Text(selectedBus!.eta, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildStatBox(Icons.groups, "Occupancy", "${selectedBus!.occupancy}%"),
                            const SizedBox(width: 12),
                            _buildStatBox(Icons.event_seat, "Available", "${selectedBus!.availableSeats} Seats"),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Arrival alert enabled for Bus #${selectedBus!.busId}!")),
                              );
                            },
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: const Text("Notify me on arrival"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

  }

  Widget _buildInteractiveTelemetryRadarMap() {
    return Container(
      color: const Color(0xFF001B3D),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: TelemetryMapGridPainter(),
            ),
          ),
          // Interactive Shuttle Pins
          ...busLocations.map((bus) {
            final isSel = selectedBus?.busId == bus.busId;
            return Positioned(
              left: bus.busId == "402" ? 180 : 280,
              top: bus.busId == "402" ? 220 : 340,
              child: InkWell(
                onTap: () => _onMarkerTapped(bus),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_bus, color: isSel ? const Color(0xFF001B3D) : Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Bus #${bus.busId}",
                        style: TextStyle(
                          color: isSel ? const Color(0xFF001B3D) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapFab(IconData icon, {bool isPrimary = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF1565C0) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF424752)),
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF006876)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF727783))),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF191C21))),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _locationTimer?.cancel();
    _webSocketSubscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

class TelemetryMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF003366).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(100, 150)
      ..lineTo(180, 220)
      ..lineTo(280, 340)
      ..lineTo(350, 420);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
