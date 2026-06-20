import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';

class EventMapScreen extends StatelessWidget {
  final CampusEvent event;
  const EventMapScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: LatLng(event.latitude, event.longitude), initialZoom: 16.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.bahria.campus_connect'),
              MarkerLayer(markers: [Marker(point: LatLng(event.latitude, event.longitude), width: 80, height: 80, child: const Icon(Icons.location_on, color: Colors.red, size: 45))]),
            ],
          ),
          Positioned(
            bottom: 30, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.place, color: Colors.blue), const SizedBox(width: 8), Expanded(child: Text(event.location))]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}