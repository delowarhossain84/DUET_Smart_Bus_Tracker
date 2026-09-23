import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:duet_smart_bus_tracker/models/user_model.dart';
import 'package:duet_smart_bus_tracker/models/bus_route.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';
import 'package:duet_smart_bus_tracker/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedNavIndex = 0;
  bool _isLoading = true;
  String _selectedRouteFilter = "All (12)";
  String _selectedDriverFilter = "All Drivers (24)";
  String _selectedTripFilter = "All Trips (38)";

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _routesKey = GlobalKey();
  final GlobalKey _driversKey = GlobalKey();
  final GlobalKey _tripsKey = GlobalKey();
  final GlobalKey _stopsKey = GlobalKey();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  List<DriverRequest> _driverRequests = [];
  List<DispatchTrip> _dispatchTrips = [];
  List<CampusStopCard> _campusStops = [];
  List<BusRoute> _routes = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshDashboard();
      }
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
    
    // Debugging for Web
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fetching Data from Live Server..."), duration: Duration(seconds: 1)),
      );
    }
    
    await AuthService.fetchDashboardData();
    await AuthService.fetchStops();
    await AuthService.fetchRoutes();
    _loadData();
    
    if (kIsWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data Fetched. Routes: ${_routes.length}, Buses: ${_stats['totalBuses'] ?? 0}"), duration: const Duration(seconds: 2)),
      );
    }
    
    setState(() => _isLoading = false);
  }

  void _loadData() {
    setState(() {
      _driverRequests = AuthService.getDriverRequests();
      _dispatchTrips = AuthService.getDispatchTrips();
      _campusStops = AuthService.getCampusStops();
      _routes = AuthService.getRoutes();
      _stats = AuthService.getSystemStats();
    });
  }

  void _navigateToSection(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    GlobalKey? targetKey;
    switch (index) {
      case 0:
        targetKey = _dashboardKey;
        break;
      case 1:
        targetKey = _routesKey;
        break;
      case 2:
        targetKey = _driversKey;
        break;
      case 3:
        targetKey = _tripsKey;
        break;
      case 4:
        targetKey = _stopsKey;
        break;
      case 5:
        targetKey = _mapKey;
        break;
      case 6:
        targetKey = _settingsKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleApproveDriver(String requestId, String name) async {
    setState(() => _isLoading = true);
    final success = await AuthService.approveDriverRequest(requestId);
    
    if (success) {
      await _refreshDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Driver '$name' activated successfully!"),
          backgroundColor: const Color(0xFF0D532B),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to activate driver."),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
    }
  }

  Future<void> _handleRejectDriver(String requestId, String name) async {
    setState(() => _isLoading = true);
    final success = await AuthService.rejectDriverRequest(requestId);
    
    if (success) {
      await _refreshDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Driver '$name' request deactivated/rejected."),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to reject driver."),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
    }
  }

  void _handleStartTrip(String tripId) {
    AuthService.startTrip(tripId);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trip started and live telemetry active!"), backgroundColor: Color(0xFF0D532B)),
    );
  }

  void _handleStopTrip(String tripId) {
    AuthService.stopTrip(tripId);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trip marked as completed."), backgroundColor: Color(0xFFBA1A1A)),
    );
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: _buildTopAppBar(context, isDesktop),
      drawer: isDesktop ? null : _buildSidebarDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop) SizedBox(width: 240, child: _buildSidebarContent()),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(key: _dashboardKey, child: _buildDashboardTitleHeader()),
                        const SizedBox(height: 24),
                        _buildTopKpiCardsRow(),
                        const SizedBox(height: 24),

                        // Prominent Pending Driver Approval Banner Card
                        _buildPendingDriversQueueCard(),

                        const SizedBox(height: 32),
                        Container(key: _routesKey, child: _buildCampusRoutesSection()),
                        const SizedBox(height: 32),
                        Container(key: _driversKey, child: _buildTransitDriversSection()),
                        const SizedBox(height: 32),
                        Container(key: _tripsKey, child: _buildDispatchTripsSection()),
                        const SizedBox(height: 32),
                        Container(key: _stopsKey, child: _buildCampusStopsSection()),
                        const SizedBox(height: 32),
                        _buildStudentDepartmentalAnalyticsSection(),
                        const SizedBox(height: 32),
                        Container(key: _mapKey, child: _buildLiveMapSection()),
                        const SizedBox(height: 32),
                        Container(key: _settingsKey, child: _buildAdminSettingsSection()),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Bar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      backgroundColor: const Color(0xFF001B3D),
      elevation: 0,
      leading: isDesktop
          ? const Icon(Icons.directions_bus, color: Colors.white, size: 28)
          : Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
      titleSpacing: 0,
      title: const Text(
        "Campus Shuttle DUET",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      actions: [
        if (isDesktop) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF002952),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF004D99)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF00E5FF), size: 8),
                SizedBox(width: 4),
                Text(
                  "TELEMETRY 100% LIVE",
                  style: TextStyle(color: Color(0xFF80D8FF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (isDesktop && MediaQuery.of(context).size.width > 1200)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exporting Fleet Log PDF...")));
            },
            icon: const Icon(Icons.download, size: 14, color: Colors.white),
            label: const Text("Export Fleet Log", style: TextStyle(color: Colors.white, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        const SizedBox(width: 8),
        if (isDesktop || MediaQuery.of(context).size.width > 600)
          ElevatedButton.icon(
            onPressed: () {
              _showBroadcastAlertModal(context);
            },
            icon: const Icon(Icons.notifications_active, size: 14, color: Colors.white),
            label: const Text("+ Broadcast Alert", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004080),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        if (!isDesktop && MediaQuery.of(context).size.width <= 600)
          IconButton(
            onPressed: () => _showBroadcastAlertModal(context),
            icon: const Icon(Icons.notifications_active, color: Colors.white),
          ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF1565C0),
          child: Text("SJ", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFFFF8A80), size: 20),
          tooltip: "Logout Admin",
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar Navigation Component
  // ---------------------------------------------------------------------------
  Widget _buildSidebarDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF001529),
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    return Material(
      color: const Color(0xFF001529),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildNavItem(0, Icons.dashboard, "Dashboard"),
          _buildNavItem(1, Icons.route, "Routes"),
          _buildNavItem(2, Icons.people, "Drivers"),
          _buildNavItem(3, Icons.departure_board, "Trips"),
          _buildNavItem(4, Icons.place, "Stops"),
          _buildNavItem(5, Icons.map, "Live Map"),
          _buildNavItem(6, Icons.settings, "Settings"),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF8A80)),
            title: const Text("Logout", style: TextStyle(color: Color(0xFFFF8A80), fontSize: 14)),
            onTap: _handleLogout,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF003366),
                  child: Text("SJ", style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sarah Jenkins", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("Operations Lead", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          onTap: () {
            _navigateToSection(index);
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Title Header
  // ---------------------------------------------------------------------------
  Widget _buildDashboardTitleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          spacing: 12,
          children: [
            const Text(
              "Bus Tracking Admin Dashboard",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001B3D)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    "Live GPS RTK Mesh Active • Updated 4s ago",
                    style: TextStyle(fontSize: 12, color: Color(0xFF006876), fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Fall Semester Active Dispatch & Campus Mobility Overview",
          style: TextStyle(fontSize: 13, color: Color(0xFF424752)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Top 4 Summary KPI Metric Cards
  // ---------------------------------------------------------------------------
  Widget _buildTopKpiCardsRow() {
    int pendingCount = _driverRequests.where((r) => r.status == RequestStatus.pending).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildKpiCard(
              title: "STUDENTS LIVE",
              mainValue: "${_stats['studentsLive'] ?? 0}",
              badgeIcon: Icons.people,
              badgeColor: const Color(0xFFD6E3FF),
              badgeIconColor: const Color(0xFF004D99),
              subtext1: "+18% morning rush peak",
              subtext2: "Peak: Central Library",
            ),
            _buildKpiCard(
              title: "ACTIVE TRIPS",
              mainValue: "${_stats['activeTrips'] ?? 0} Running",
              badgeIcon: Icons.directions_bus,
              badgeColor: const Color(0xFFD6E3FF),
              badgeIconColor: const Color(0xFF004D99),
              subtext1: "Out of ${_stats['totalRoutes'] ?? 0} scheduled routes",
              subtext2: "Headway avg 6.2m",
            ),
            _buildKpiCard(
              title: "ONLINE DRIVERS",
              mainValue: "${_stats['onlineDrivers'] ?? 0} On Shift",
              badgeIcon: Icons.drive_eta,
              badgeColor: const Color(0xFFE6F4EA),
              badgeIconColor: Colors.green[800]!,
              subtext1: "3 available for standby",
              subtext2: "Shift 94% Covered",
            ),
            _buildKpiCard(
              title: "UNACTIVATED DRIVERS",
              mainValue: "$pendingCount Pending",
              badgeIcon: Icons.security,
              badgeColor: const Color(0xFFFFDAD6),
              badgeIconColor: const Color(0xFFBA1A1A),
              subtext1: "CDL & Audit Review Required",
              subtext2: "",
              actionWidget: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedDriverFilter = "Unactivated / Pending (3)";
                  });
                  _navigateToSection(2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDAD6),
                  foregroundColor: const Color(0xFF93000A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text("Review Queue", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String mainValue,
    required IconData badgeIcon,
    required Color badgeColor,
    required Color badgeIconColor,
    required String subtext1,
    required String subtext2,
    Widget? actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E2EA)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(badgeIcon, size: 18, color: badgeIconColor),
              ),
            ],
          ),
          Text(mainValue, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtext1.isNotEmpty) Text(subtext1, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0)), overflow: TextOverflow.ellipsis),
                    if (subtext2.isNotEmpty) Text(subtext2, style: const TextStyle(fontSize: 10, color: Color(0xFF727783)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dedicated Prominent "Pending Driver Approval Queue" Banner
  // ---------------------------------------------------------------------------
  Widget _buildPendingDriversQueueCard() {
    final pendingList = _driverRequests.where((r) => r.status == RequestStatus.pending).toList();

    if (pendingList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB4A9), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFFDAD6), shape: BoxShape.circle),
                child: const Icon(Icons.pending_actions, color: Color(0xFFBA1A1A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${pendingList.length} Pending Driver Applications Awaiting Approval",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF410002)),
                    ),
                    const Text(
                      "Review driver applicant credentials below and click Accept or Reject.",
                      style: TextStyle(fontSize: 12, color: Color(0xFF727783)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFFFB4A9)),
          const SizedBox(height: 8),

          ...pendingList.map((req) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFDBC9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFFFDAD6),
                          child: Text(
                            req.driverName.isNotEmpty ? req.driverName[0].toUpperCase() : "D",
                            style: const TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("${req.email} • ${req.phone}", style: const TextStyle(fontSize: 12, color: Color(0xFF424752))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(12)),
                          child: const Text("PENDING APPROVAL", style: TextStyle(color: Color(0xFFBA1A1A), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF727783)),
                            const SizedBox(width: 4),
                            Text("License: ${req.licenseNumber}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_bus_outlined, size: 14, color: Color(0xFF727783)),
                            const SizedBox(width: 4),
                            Text("Assigned: ${req.requestedBus}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleRejectDriver(req.id, req.driverName),
                            icon: const Icon(Icons.close, color: Color(0xFFBA1A1A), size: 16),
                            label: const Text("Reject Request"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBA1A1A),
                              side: const BorderSide(color: Color(0xFFBA1A1A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleApproveDriver(req.id, req.driverName),
                            icon: const Icon(Icons.check, color: Colors.white, size: 16),
                            label: const Text("Accept & Activate Driver"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D532B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Campus Routes Section
  // ---------------------------------------------------------------------------
  Widget _buildCampusRoutesSection() {
    final routeFilters = ["All (12)", "Active (9)", "Modified/Detour (2)", "Inactive (1)"];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route, color: Color(0xFF1565C0), size: 24),
                  SizedBox(width: 8),
                  Text("Campus Routes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...routeFilters.map((f) {
                    final isSel = _selectedRouteFilter == f;
                    return ChoiceChip(
                      label: Text(f, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : const Color(0xFF424752))),
                      selected: isSel,
                      selectedColor: const Color(0xFF001B3D),
                      backgroundColor: const Color(0xFFECEDF6),
                      onSelected: (val) => setState(() => _selectedRouteFilter = f),
                    );
                  }),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateRouteModal(context);
                    },
                    icon: const Icon(Icons.add_road, size: 16, color: Colors.white),
                    label: const Text("New Route", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001B3D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateBusModal(context);
                    },
                    icon: const Icon(Icons.directions_bus, size: 16, color: Colors.white),
                    label: const Text("New Bus", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Manage active transit lines, timetable frequency, and assign campus mobility corridors", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
          const SizedBox(height: 20),

          // Route Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 2 : 1;
              if (_routes.isEmpty) {
                return const Center(child: Text("No routes found in backend. Create one below."));
              }
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: constraints.maxWidth < 600 ? 1.65 : 2.2,
                children: _routes.map((route) => _buildRouteCard(
                    lineName: route.name,
                    routeName: "Code: ${route.code}",
                    statusText: route.isOnTime ? "Active" : "Inactive",
                    isDetour: !route.isOnTime,
                    stopsInfo: route.stops,
                    fleetAssigned: "${route.activeBuses} Buses",
                    frequency: route.frequency,
                  )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard({
    required String lineName,
    required String routeName,
    required String statusText,
    required bool isDetour,
    required String stopsInfo,
    required String fleetAssigned,
    required String frequency,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD6E3FF), borderRadius: BorderRadius.circular(6)),
                child: Text(lineName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF004D99))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDetour ? const Color(0xFFFFDBC9) : const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDetour ? const Color(0xFF93000A) : Colors.green[800]),
                ),
              ),
            ],
          ),
          Text(routeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001B3D)), overflow: TextOverflow.ellipsis),
          Text(stopsInfo, style: const TextStyle(fontSize: 11, color: Color(0xFF727783)), overflow: TextOverflow.ellipsis),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assigned Fleet: $fleetAssigned", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF001B3D)), overflow: TextOverflow.ellipsis),
                    Text("Frequency: $frequency", style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1565C0)),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFBA1A1A)),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Transit Drivers Table Section (Dynamic Filtered & Overflow-Safe)
  // ---------------------------------------------------------------------------
  Widget _buildTransitDriversSection() {
    final driverFilters = ["All Drivers (24)", "Activated / Active (19)", "Unactivated / Pending (3)", "Off-Duty (2)"];

    // Dynamic Filtered Driver List
    List<DriverRequest> filteredDrivers = _driverRequests;
    if (_selectedDriverFilter.contains("Pending") || _selectedDriverFilter.contains("Unactivated")) {
      filteredDrivers = _driverRequests.where((r) => r.status == RequestStatus.pending).toList();
    } else if (_selectedDriverFilter.contains("Active") || _selectedDriverFilter.contains("Activated")) {
      filteredDrivers = _driverRequests.where((r) => r.status == RequestStatus.approved).toList();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_alt, color: Color(0xFF1565C0), size: 24),
                  SizedBox(width: 8),
                  Text("Transit Drivers Directory", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: driverFilters.map((f) {
                  final isSel = _selectedDriverFilter == f;
                  return ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : const Color(0xFF424752))),
                    selected: isSel,
                    selectedColor: const Color(0xFF001B3D),
                    backgroundColor: const Color(0xFFECEDF6),
                    onSelected: (val) => setState(() => _selectedDriverFilter = f),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Monitor driver certifications, on-duty status, and activation workflows", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
          const SizedBox(height: 20),

          // Drivers Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F4F8)),
              columns: const [
                DataColumn(label: SizedBox(width: 160, child: Text("DRIVER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 110, child: Text("CONTACT PHONE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 180, child: Text("LICENSE & CREDENTIALS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 160, child: Text("ASSIGNED BUS & ROUTE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 120, child: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 140, child: Text("ACTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
              ],
              rows: filteredDrivers.map((req) {
                final isPending = req.status == RequestStatus.pending;
                final isApproved = req.status == RequestStatus.approved;

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isPending ? const Color(0xFFFFDAD6) : const Color(0xFFD6E3FF),
                              child: Text(
                                req.driverName.isNotEmpty ? req.driverName[0].toUpperCase() : "D",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPending ? const Color(0xFFBA1A1A) : const Color(0xFF004D99)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    req.driverName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    req.licenseNumber,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF727783)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: Text(req.phone, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          req.credentialsInfo,
                          style: TextStyle(fontSize: 10, color: isPending ? const Color(0xFFBA1A1A) : const Color(0xFF424752)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          req.requestedBus,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFFFDAD6)
                              : (req.isOnline ? const Color(0xFFE6F4EA) : const Color(0xFFD6E3FF)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPending ? "Pending" : (req.isOnline ? "Online" : "Standby"),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPending ? const Color(0xFFBA1A1A) : (req.isOnline ? Colors.green[800] : const Color(0xFF004D99)),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPending) ...[
                              ElevatedButton(
                                onPressed: () => _handleApproveDriver(req.id, req.driverName),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF001B3D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                                child: const Text("Activate", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ] else if (isApproved) ...[
                              OutlinedButton(
                                onPressed: () => _handleRejectDriver(req.id, req.driverName),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFBA1A1A),
                                  side: const BorderSide(color: Color(0xFFBA1A1A)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                                child: const Text("Deactivate", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dispatch & Scheduled Trips Table Section
  // ---------------------------------------------------------------------------
  Widget _buildDispatchTripsSection() {
    final tripFilters = ["All Trips (38)", "Running (14)", "Scheduled (18)", "Completed (6)"];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, color: Color(0xFF1565C0), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("Dispatch & Scheduled Trips", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showDispatchTripModal(context),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text("Dispatch Trip", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D532B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ...tripFilters.map((f) {
                    final isSel = _selectedTripFilter == f;
                    return ChoiceChip(
                      label: Text(f, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : const Color(0xFF424752))),
                      selected: isSel,
                      selectedColor: const Color(0xFF001B3D),
                      backgroundColor: const Color(0xFFECEDF6),
                      onSelected: (val) => setState(() => _selectedTripFilter = f),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Real-time timetable execution, live passenger loads, and trip telemetry", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
          const SizedBox(height: 20),

          // Trips Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F4F8)),
              columns: const [
                DataColumn(label: SizedBox(width: 80, child: Text("TRIP ID", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 130, child: Text("ROUTE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 160, child: Text("BUS & TYPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 120, child: Text("DRIVER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 120, child: Text("START / ETA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 120, child: Text("STUDENTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783)), overflow: TextOverflow.ellipsis))),
                DataColumn(label: SizedBox(width: 90, child: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
                DataColumn(label: SizedBox(width: 100, child: Text("ACTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))))),
              ],
              rows: _dispatchTrips.map((trip) {
                final isRunning = trip.status == "Running";
                final isScheduled = trip.status == "Scheduled";

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: Text(trip.tripId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF001B3D))),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(trip.routeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getBusTypeColor(trip.type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(_getBusTypeIcon(trip.type), size: 14, color: _getBusTypeColor(trip.type)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(trip.busId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text("${trip.occupancyCurrent}/${trip.occupancyMax} (${trip.occupancyPercentage}%)", style: const TextStyle(fontSize: 9, color: Color(0xFF727783))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: const Color(0xFF003366),
                              child: Text(trip.driverInitials, style: const TextStyle(fontSize: 9, color: Colors.white)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(trip.driverName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(trip.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(trip.etaMessage, style: TextStyle(fontSize: 9, color: trip.etaMessage.contains("Delay") ? Colors.red : Colors.green[800]), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Color(0xFF1565C0)),
                            const SizedBox(width: 4),
                            Text("${trip.studentsTrackingCount}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRunning ? const Color(0xFFD6E3FF) : (trip.status == "Completed" ? const Color(0xFFE6F4EA) : const Color(0xFFECEDF6)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          trip.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isRunning ? const Color(0xFF004D99) : (trip.status == "Completed" ? Colors.green[800] : const Color(0xFF727783)),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            if (isScheduled)
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Colors.green, size: 22),
                                onPressed: () => _handleStartTrip(trip.tripId),
                                tooltip: "Start Trip",
                              ),
                            if (isRunning)
                              IconButton(
                                icon: const Icon(Icons.stop_circle, color: Colors.red, size: 22),
                                onPressed: () => _handleStopTrip(trip.tripId),
                                tooltip: "Stop Trip",
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBusTypeIcon(BusType type) {
    switch (type) {
      case BusType.micro:
        return Icons.airport_shuttle;
      case BusType.teacher:
        return Icons.school;
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
      default:
        return const Color(0xFF1565C0);
    }
  }

  // ---------------------------------------------------------------------------
  // Campus Stops & Waypoints Section
  // ---------------------------------------------------------------------------
  Widget _buildCampusStopsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place, color: Color(0xFF1565C0), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Campus Stops & Waypoints", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showCreateStopModal(context);
                },
                icon: const Icon(Icons.add_location, size: 16, color: Colors.white),
                label: const Text("New Stop", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001B3D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Geo-fenced pickup points, shelter digital displays, and live student queue monitoring", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
          const SizedBox(height: 20),

          // Stop Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 2 : 1;
              if (_campusStops.isEmpty) {
                return const Center(child: Text("No stops found in backend. Add one to see it here."));
              }
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: _campusStops.map((stop) => _buildStopCard(stop)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(CampusStopCard stop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(10)),
                child: const Text("Active Stop", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
              Text(stop.stopCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF727783))),
            ],
          ),
          Text(stop.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
          Text(stop.locationSubtext, style: const TextStyle(fontSize: 11, color: Color(0xFF727783))),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stop.routes
                .map((r) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFD6E3FF), borderRadius: BorderRadius.circular(4)),
                      child: Text(r, style: const TextStyle(fontSize: 10, color: Color(0xFF004D99), fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Student Queue: ${stop.studentQueueCount} waiting", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
              Text("Est. Pickup Wait: ${stop.estWaitTime}", style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Student Departmental Analytics Section
  // ---------------------------------------------------------------------------
  Widget _buildStudentDepartmentalAnalyticsSection() {
    final Map<String, int> deptStats = AuthService.getDepartmentStats();
    final totalStudents = deptStats.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF1565C0), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Student Commute Analytics by Department", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD6E3FF), borderRadius: BorderRadius.circular(12)),
                child: Text("$totalStudents Students", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF004D99))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Identify student app usage and commute demand across DUET academic departments and semesters", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
          const SizedBox(height: 20),

          ...deptStats.entries.map((entry) {
            final deptName = entry.key;
            final count = entry.value;
            final ratio = totalStudents > 0 ? count / totalStudents : 0.0;
            final percentage = (ratio * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(deptName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001B3D)), overflow: TextOverflow.ellipsis),
                      ),
                      Text("$count Students ($percentage%)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1565C0))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFECEDF6),
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactive Live Map Section
  // ---------------------------------------------------------------------------
  Widget _buildLiveMapSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Color(0xFF1565C0), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Fleet Live Map Telemetry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fullscreen map telemetry expanded")));
                },
                icon: const Icon(Icons.fullscreen, size: 16, color: Colors.white),
                label: const Text("Expand Live Map", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001B3D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Live GPS RTK tracking of active shuttles, driver positions, and stop congestion", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
          const SizedBox(height: 20),

          // Interactive Telemetry Canvas Radar
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF001B3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF003366)),
            ),
            child: Stack(
              children: [
                // Radar grid lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: RadarGridPainter(),
                  ),
                ),
                // Shuttle Markers
                Positioned(
                  left: 120,
                  top: 80,
                  child: _buildMapBusPin("Bus #104", "Blue Line", const Color(0xFF1565C0), BusType.student),
                ),
                Positioned(
                  right: 180,
                  top: 140,
                  child: _buildMapBusPin("Bus T-05", "Staff Shuttle", Colors.teal, BusType.teacher),
                ),
                Positioned(
                  left: 260,
                  bottom: 60,
                  child: _buildMapBusPin("Bus M-12", "Micro Link", Colors.orange[800]!, BusType.micro),
                ),
                // Center Radar Sync Info
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar, color: Color(0xFF00E5FF), size: 14),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text("14 Shuttles Broadcasting • Live GPS Mesh RTK Sync 100%", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBusPin(String busId, String lineName, Color color, BusType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getBusTypeIcon(type), color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text("$busId ($lineName)", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings Section
  // ---------------------------------------------------------------------------
  Widget _buildAdminSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Color(0xFF1565C0), size: 24),
                SizedBox(width: 8),
                Text("Admin System Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001B3D))),
              ],
            ),
            const SizedBox(height: 6),
            const Text("Configure broadcast thresholds, dispatch frequency, and driver approval rules", style: TextStyle(fontSize: 12, color: Color(0xFF727783))),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("Require HR Background Audit for New Drivers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Enforce background check upload before activating driver accounts"),
              value: true,
              onChanged: (val) {},
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Automated Peak Hour Dispatch Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Send notifications to students when queue size exceeds 30 waiting"),
              value: true,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modals
  // ---------------------------------------------------------------------------
  void _showDispatchTripModal(BuildContext context) {
    String selectedRoute = "Blue Line Express";
    String selectedBus = "Bus #104";
    String selectedDriver = "Marcus Vance";
    BusType selectedType = BusType.student;

    final List<String> routes = ["Blue Line Express", "Central Quad Loop", "Staff Housing Shuttle", "Campus Micro Link"];
    final List<String> buses = ["Bus #104", "Bus #108", "Bus T-05", "Bus M-12"];
    final List<String> drivers = ["Marcus Vance", "Elena Rostova", "David Kim", "John Doe"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text("Dispatch New Live Trip", style: TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              DropdownButton<String>(
                value: selectedRoute,
                isExpanded: true,
                onChanged: (val) => setModalState(() => selectedRoute = val!),
                items: routes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              ),
              const SizedBox(height: 12),
              const Text("Select Vehicle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              DropdownButton<String>(
                value: selectedBus,
                isExpanded: true,
                onChanged: (val) {
                  setModalState(() {
                    selectedBus = val!;
                    if (val.contains("T-")) {
                      selectedType = BusType.teacher;
                    } else if (val.contains("M-")) {
                      selectedType = BusType.micro;
                    } else {
                      selectedType = BusType.student;
                    }
                  });
                },
                items: buses.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              ),
              const SizedBox(height: 12),
              const Text("Select Driver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              DropdownButton<String>(
                value: selectedDriver,
                isExpanded: true,
                onChanged: (val) => setModalState(() => selectedDriver = val!),
                items: drivers.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                AuthService.dispatchNewTrip(
                  routeName: selectedRoute,
                  busId: selectedBus,
                  type: selectedType,
                  driverName: selectedDriver,
                );
                _loadData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New trip dispatched and active!"), backgroundColor: Color(0xFF0D532B)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D532B), foregroundColor: Colors.white),
              child: const Text("Start Live Dispatch"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRouteModal(BuildContext context) {
    final routeNameCtrl = TextEditingController(text: "DUET-DU");
    final routeCodeCtrl = TextEditingController(text: "DUET-DU");
    final frequencyCtrl = TextEditingController(text: "A Bus which travel from duet to du each data");
    final stopSearchCtrl = TextEditingController();
    final manualStopIdCtrl = TextEditingController();

    // Store custom or selected stops as list of Map { "stop_id": int, "name": String }
    final List<Map<String, dynamic>> routeStopsList = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final searchQuery = stopSearchCtrl.text.toLowerCase().trim();
          final filteredStops = _campusStops.where((stop) {
            if (searchQuery.isEmpty) return true;
            return stop.name.toLowerCase().contains(searchQuery) ||
                stop.stopId.toString().contains(searchQuery);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_road, color: Color(0xFF001B3D)),
                SizedBox(width: 8),
                Expanded(child: Text("Create New Campus Route", style: TextStyle(fontSize: 16))),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Route Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: routeNameCtrl,
                      decoration: InputDecoration(
                        hintText: "e.g. DUET-DU",
                        filled: true,
                        fillColor: const Color(0xFFF2F4F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Route Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: routeCodeCtrl,
                      decoration: InputDecoration(
                        hintText: "e.g. DUET-DU",
                        filled: true,
                        fillColor: const Color(0xFFF2F4F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: frequencyCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "e.g. A Bus which travel from duet to du each data",
                        filled: true,
                        fillColor: const Color(0xFFF2F4F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Route Waypoints (stop_ids & stop_order)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),

                    // Display added ordered stops list
                    if (routeStopsList.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: routeStopsList.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE1E2EA)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF001B3D),
                                    child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'] ?? "Stop ${item['stop_id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text("stop_id: ${item['stop_id']} • stop_order: ${idx + 1}", style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setModalState(() {
                                        routeStopsList.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Search Stops Input
                    if (_campusStops.isNotEmpty) ...[
                      TextField(
                        controller: stopSearchCtrl,
                        onChanged: (val) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: "Search stops by name or ID...",
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF2F4F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (filteredStops.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(color: const Color(0xFFF9FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E2EA))),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredStops.length,
                            itemBuilder: (context, i) {
                              final stop = filteredStops[i];
                              final stopIdInt = int.tryParse(stop.stopId) ?? (i + 1);
                              final isAlreadyAdded = routeStopsList.any((s) => s['stop_id'] == stopIdInt);
                              return ListTile(
                                dense: true,
                                title: Text(stop.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text("ID: $stopIdInt", style: const TextStyle(fontSize: 10)),
                                trailing: isAlreadyAdded
                                    ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                    : const Icon(Icons.add_circle_outline, color: Color(0xFF001B3D), size: 18),
                                onTap: isAlreadyAdded
                                    ? null
                                    : () {
                                        setModalState(() {
                                          routeStopsList.add({
                                            "stop_id": stopIdInt,
                                            "name": stop.name,
                                          });
                                        });
                                      },
                              );
                            },
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text("No matching stops found in database.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      const SizedBox(height: 12),
                    ],

                    // Direct Manual Stop ID Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: manualStopIdCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Enter Stop ID manually (e.g. 1, 2, 3)",
                              hintStyle: const TextStyle(fontSize: 11),
                              filled: true,
                              fillColor: const Color(0xFFF2F4F8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final inputId = int.tryParse(manualStopIdCtrl.text.trim());
                            if (inputId != null) {
                              setModalState(() {
                                if (!routeStopsList.any((s) => s['stop_id'] == inputId)) {
                                  routeStopsList.add({
                                    "stop_id": inputId,
                                    "name": "Stop $inputId",
                                  });
                                }
                                manualStopIdCtrl.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001B3D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Add ID", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (routeNameCtrl.text.isEmpty || routeCodeCtrl.text.isEmpty) return;

                  final stopIdsList = routeStopsList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return {
                      "stop_id": item['stop_id'] as int,
                      "stop_order": index + 1,
                    };
                  }).toList();

                  setState(() => _isLoading = true);
                  final success = await AuthService.createRoute(
                    name: routeNameCtrl.text,
                    code: routeCodeCtrl.text,
                    description: frequencyCtrl.text,
                    stopIds: stopIdsList,
                  );

                  if (!mounted) return;
                  Navigator.pop(ctx);

                  if (success) {
                    await _refreshDashboard();
                    if (mounted) {
                      setState(() {}); // Force UI update
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("New route '${routeNameCtrl.text}' created!"), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to create route on backend."), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001B3D), foregroundColor: Colors.white),
                child: const Text("Save Route"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateBusModal(BuildContext context) {
    if (_routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must create a Route first before creating a Bus."), backgroundColor: Colors.orange),
      );
      return;
    }

    final busNameCtrl = TextEditingController();
    final regNumCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: "40");
    BusRoute selectedRouteForBus = _routes.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.directions_bus, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Expanded(child: Text("Register New Bus", style: TextStyle(fontSize: 16))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text("Bus Name / ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: busNameCtrl,
                decoration: InputDecoration(
                  hintText: "e.g. Bus #104",
                  filled: true,
                  fillColor: const Color(0xFFF2F4F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              const Text("Registration Number", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: regNumCtrl,
                decoration: InputDecoration(
                  hintText: "e.g. DH-B-1234",
                  filled: true,
                  fillColor: const Color(0xFFF2F4F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Capacity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF2F4F8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Assign to Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF2F4F8), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BusRoute>(
                    value: selectedRouteForBus,
                    isExpanded: true,
                    onChanged: (BusRoute? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          selectedRouteForBus = newValue;
                        });
                      }
                    },
                    items: _routes.map<DropdownMenuItem<BusRoute>>((BusRoute value) {
                      return DropdownMenuItem<BusRoute>(
                        value: value,
                        child: Text(value.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (busNameCtrl.text.isEmpty || regNumCtrl.text.isEmpty) return;
                
                setState(() => _isLoading = true);
                final success = await AuthService.createBus(
                  name: busNameCtrl.text,
                  registrationNumber: regNumCtrl.text,
                  capacity: int.tryParse(capacityCtrl.text) ?? 40,
                  routeId: int.tryParse(selectedRouteForBus.id) ?? 1,
                );
                
                if (!mounted) return;
                Navigator.pop(ctx);
                
                if (success) {
                  await _refreshDashboard();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("New bus '${busNameCtrl.text}' registered!"), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to register bus on backend."), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              child: const Text("Register Bus"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateStopModal(BuildContext context) {
    final stopNameCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: "24.0176");
    final lngCtrl = TextEditingController(text: "90.4196");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_location_alt, color: Color(0xFF001B3D)),
            SizedBox(width: 8),
            Expanded(child: Text("Create New Campus Stop", style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Station Stop Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: stopNameCtrl,
              decoration: InputDecoration(
                hintText: "e.g. Science Library Gate",
                filled: true,
                fillColor: const Color(0xFFF2F4F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Latitude", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: "e.g. 24.0176",
                          filled: true,
                          fillColor: const Color(0xFFF2F4F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Longitude", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: "e.g. 90.4196",
                          filled: true,
                          fillColor: const Color(0xFFF2F4F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (stopNameCtrl.text.isEmpty) return;

              final parsedLat = double.tryParse(latCtrl.text) ?? 24.0176;
              final parsedLng = double.tryParse(lngCtrl.text) ?? 90.4196;

              setState(() => _isLoading = true);
              final success = await AuthService.createStop(
                name: stopNameCtrl.text,
                latitude: parsedLat,
                longitude: parsedLng,
              );

              if (!mounted) return;
              Navigator.pop(ctx);

              if (success) {
                await _refreshDashboard();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("New stop '${stopNameCtrl.text}' added!"), backgroundColor: Colors.green),
                  );
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to add stop on backend."), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001B3D), foregroundColor: Colors.white),
            child: const Text("Save Stop"),
          ),
        ],
      ),
    );
  }

  void _showBroadcastAlertModal(BuildContext context) {
    final alertController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text("Quick Broadcast Alert"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Send an instant emergency broadcast or delay notice to all students:", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: alertController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g. Route A experiencing 10m traffic delay near North Gate.",
                filled: true,
                fillColor: const Color(0xFFF2F4F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Broadcast alert sent to all student devices!"), backgroundColor: Color(0xFF001B3D)),
              );
            },
            icon: const Icon(Icons.send, size: 16, color: Colors.white),
            label: const Text("Broadcast Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001B3D),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Custom Painter for Telemetry Radar Grid
class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF003366).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw radar circles
    final center = Offset(size.width / 2, size.height / 2);
    final circlePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 50, circlePaint);
    canvas.drawCircle(center, 100, circlePaint);
    canvas.drawCircle(center, 150, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
