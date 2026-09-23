import 'package:flutter/material.dart';
import 'services/bus_service.dart';
import 'models/bus_route.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<BusAlert> alerts = BusService.getMockAlerts();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE1E2EA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: alert.isWarning ? const Color(0xFFFFDAD6) : const Color(0xFFD6E3FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alert.isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: alert.isWarning ? const Color(0xFFBA1A1A) : const Color(0xFF004D99),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(alert.description, style: const TextStyle(color: Color(0xFF424752), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(alert.time, style: const TextStyle(color: Color(0xFF727783), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
