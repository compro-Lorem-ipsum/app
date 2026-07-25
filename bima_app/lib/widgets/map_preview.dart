// Widget peta kecil (preview lokasi) berbasis flutter_map, dipakai di
// halaman-halaman yang menampilkan koordinat GPS.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'app_theme.dart';

class MapPreview extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double height;
  final double borderRadius;

  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.borderRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null && !(latitude == 0 && longitude == 0);

    if (!hasLocation) {
      return Container(
        width: double.infinity,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.location_off_outlined, color: AppColors.disabled, size: 32),
      );
    }

    final point = LatLng(latitude!, longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bima_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.primary, size: 36),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
