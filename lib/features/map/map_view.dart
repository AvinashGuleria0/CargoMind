import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/map_style.dart';
import '../../models/shipment_model.dart';
import '../dashboard/providers.dart';

// Custom Polyline Decoder (Google Maps format) to avoid external package constraints
List<LatLng> decodeEncodedPolyline(String encoded) {
  List<LatLng> polyStr = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    polyStr.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
  }
  return polyStr;
}

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _hasZoomedInitially = false;

  // Center of India fallback
  final LatLng _center = const LatLng(20.5937, 78.9629);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Apply the sophisticated dark theme to the map immediately
    mapController?.setMapStyle(MapStyle.darkJson);
  }

  void _processShipments(List<ShipmentModel> shipments) {
    if (shipments.isEmpty) return;

    Set<Polyline> newPolylines = {};
    Set<Marker> newMarkers = {};
    
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var shipment in shipments) {
      if (shipment.routeData.encodedPolyline.isEmpty) continue;

      // 1. Decode Polyline using custom math (No API Key needed)
      List<LatLng> polylineCoordinates = decodeEncodedPolyline(shipment.routeData.encodedPolyline);

      if (polylineCoordinates.isEmpty) continue;

      // 2. Determine glowing color based on status
      Color polylineColor;
      Color markerColor;
      if (shipment.status == ShipmentStatus.onTrack) {
        polylineColor = Colors.greenAccent.shade400; // Glowing green
        markerColor = Colors.green;
      } else if (shipment.status == ShipmentStatus.diverted || shipment.status == ShipmentStatus.critical) {
        polylineColor = Colors.redAccent.shade400; // Glowing neon red/orange
        markerColor = Colors.red;
      } else {
        polylineColor = Colors.blueAccent;
        markerColor = Colors.blue;
      }

      // Add actual polyline
      newPolylines.add(
        Polyline(
          polylineId: PolylineId(shipment.id),
          color: polylineColor,
          points: polylineCoordinates,
          width: 5,
          geodesic: true,
        ),
      );

      // Add pulsing glow effect underneath the main line
      newPolylines.add(
        Polyline(
          polylineId: PolylineId('${shipment.id}_glow'),
          color: polylineColor.withOpacity(0.3),
          points: polylineCoordinates,
          width: 10, // Thicker transparent line
          geodesic: true,
        ),
      );

      // Add Truck Marker
      final truckLat = shipment.telemetry.currentLocation.lat;
      final truckLng = shipment.telemetry.currentLocation.lng;
      
      newMarkers.add(
        Marker(
          markerId: MarkerId('truck_${shipment.id}'),
          position: LatLng(truckLat, truckLng),
          infoWindow: InfoWindow(title: shipment.id, snippet: shipment.status.label),
        ),
      );

      // Expand bounding box to fit all coordinate points of the route
      for (var point in polylineCoordinates) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    setState(() {
      _polylines = newPolylines;
      _markers = newMarkers;
    });

    // 4. Zoom to fit
    if (minLat < maxLat && minLng < maxLng) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      if (!_hasZoomedInitially && mapController != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
          _hasZoomedInitially = true; // Only do big bounds animation once so user can freely pan after
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for live Firestore updates here
    ref.listen<AsyncValue<List<ShipmentModel>>>(activeShipmentsProvider, (previous, next) {
      next.whenData((shipments) => _processShipments(shipments));
    });

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 5.0,
      ),
      polylines: _polylines,
      markers: _markers,
      // Hide generic map UI for a cleaner SaaS look
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}
