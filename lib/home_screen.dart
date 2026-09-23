import 'package:flutter/material.dart';
import 'package:duet_smart_bus_tracker/services/bus_service.dart';
import 'package:duet_smart_bus_tracker/models/bus_route.dart';
import 'package:duet_smart_bus_tracker/live_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<BusLocation>> _activeTripsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTrips();
  }

  void _refreshTrips() {
    print("REFRESH TRIPS CALLED");

    setState(() {
      _activeTripsFuture = BusService.fetchStudentActiveTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshTrips();
            await _activeTripsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Simple App Header
                Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Color(0xFF1565C0), size: 30),
                    const SizedBox(width: 8),
                    const Text(
                      "DUET Bus Tracker",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.account_circle, color: Color(0xFF424752), size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Prominent Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE1E2EA)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Search by route or destination...",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Color(0xFF1565C0)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Live Trips Section Header
                const Row(
                  children: [
                    Icon(Icons.sensors, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Live Active Trips",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191C21)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Trips List
                FutureBuilder<List<BusLocation>>(
                  future: _activeTripsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildNoActiveTrips();
                    }

                    return Column(
                      children: snapshot.data!
                          .map((trip) => _buildTripCard(context, trip))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveTrips() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.bus_alert, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No buses are currently active",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Pull down to refresh",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, BusLocation trip) {
    print("BUILDING CARD: ${trip.tripId}");

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("CARD CLICKED"),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveMapScreen(
              tripId: trip.tripId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E2EA)),
        ),
        child: Row(
          children: [
            // Route Icon based on BusType
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getBusTypeColor(trip.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getBusTypeIcon(trip.type), color: _getBusTypeColor(trip.type)),
            ),
            const SizedBox(width: 16),
            // Trip Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.busId.toLowerCase().startsWith('bus') ? trip.busId : "Bus #${trip.busId}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeBadge(trip.type),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Route: ${trip.routeCode}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_alt, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "${trip.availableSeats} seats left",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ETA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trip.eta,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _getBusTypeColor(trip.type)
                  ),
                ),
                const Text(
                  "Arrival",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBusTypeIcon(BusType type) {
    switch (type) {
      case BusType.micro:
        return Icons.airport_shuttle;
      case BusType.teacher:
        return Icons.school;
      case BusType.student:
      default:
        return Icons.directions_bus;
    }
  }

  Color _getBusTypeColor(BusType type) {
    switch (type) {
      case BusType.teacher:
        return Colors.teal;
      case BusType.micro:
        return Colors.orange[800]!;
      case BusType.student:
      default:
        return const Color(0xFF1565C0);
    }
  }

  Widget _buildTypeBadge(BusType type) {
    String label;
    Color color;

    switch (type) {
      case BusType.teacher:
        label = "TEACHER";
        color = Colors.teal;
        break;
      case BusType.micro:
        label = "MICRO";
        color = Colors.orange[800]!;
        break;
      case BusType.student:
      default:
        label = "STUDENT";
        color = const Color(0xFF1565C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
