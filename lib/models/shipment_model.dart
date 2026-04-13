import 'package:cloud_firestore/cloud_firestore.dart';

enum ShipmentStatus {
  onTrack,
  critical,
  diverted,
  unknown;

  static ShipmentStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ON_TRACK':
        return ShipmentStatus.onTrack;
      case 'CRITICAL':
        return ShipmentStatus.critical;
      case 'DIVERTED':
        return ShipmentStatus.diverted;
      default:
        return ShipmentStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case ShipmentStatus.onTrack:
        return 'ON_TRACK';
      case ShipmentStatus.critical:
        return 'CRITICAL';
      case ShipmentStatus.diverted:
        return 'DIVERTED';
      case ShipmentStatus.unknown:
        return 'UNKNOWN';
    }
  }
}

class ShipmentModel {
  final String id;
  final ShipmentStatus status;
  final Cargo cargo;
  final Telemetry telemetry;
  final RouteData routeData;
  final AgentMetadata agentMetadata;

  const ShipmentModel({
    required this.id,
    required this.status,
    required this.cargo,
    required this.telemetry,
    required this.routeData,
    required this.agentMetadata,
  });

  factory ShipmentModel.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return ShipmentModel.fromMap(doc.data(), doc.id);
  }

  factory ShipmentModel.fromMap(Map<String, dynamic> map, String id) {
    return ShipmentModel(
      id: id,
      status: ShipmentStatus.fromString(map['status'] as String?),
      cargo: Cargo.fromMap((map['cargo'] as Map<String, dynamic>?) ?? const {}),
      telemetry: Telemetry.fromMap((map['telemetry'] as Map<String, dynamic>?) ?? const {}),
      routeData: RouteData.fromMap((map['route_data'] as Map<String, dynamic>?) ?? const {}),
      agentMetadata: AgentMetadata.fromMap((map['agent_metadata'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.label,
      'cargo': cargo.toMap(),
      'telemetry': telemetry.toMap(),
      'route_data': routeData.toMap(),
      'agent_metadata': agentMetadata.toMap(),
    };
  }
}

class Cargo {
  final String type;
  final String description;
  final double valueInr;
  final int spoilageTimeHours;

  const Cargo({
    required this.type,
    required this.description,
    required this.valueInr,
    required this.spoilageTimeHours,
  });

  factory Cargo.fromMap(Map<String, dynamic> map) {
    return Cargo(
      type: (map['type'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      valueInr: _toDouble(map['value_inr']),
      spoilageTimeHours: _toInt(map['spoilage_time_hours']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'value_inr': valueInr,
      'spoilage_time_hours': spoilageTimeHours,
    };
  }
}

class Telemetry {
  final String vehicleId;
  final CurrentLocation currentLocation;
  final double bearing;
  final double temperatureCelsius;

  const Telemetry({
    required this.vehicleId,
    required this.currentLocation,
    required this.bearing,
    required this.temperatureCelsius,
  });

  factory Telemetry.fromMap(Map<String, dynamic> map) {
    return Telemetry(
      vehicleId: (map['vehicle_id'] ?? '').toString(),
      currentLocation: CurrentLocation.fromMap(
        (map['current_location'] as Map<String, dynamic>?) ?? const {},
      ),
      bearing: _toDouble(map['bearing']),
      temperatureCelsius: _toDouble(map['temperature_celsius']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'current_location': currentLocation.toMap(),
      'bearing': bearing,
      'temperature_celsius': temperatureCelsius,
    };
  }
}

class CurrentLocation {
  final double lat;
  final double lng;

  const CurrentLocation({
    required this.lat,
    required this.lng,
  });

  factory CurrentLocation.fromMap(Map<String, dynamic> map) {
    return CurrentLocation(
      lat: _toDouble(map['lat']),
      lng: _toDouble(map['lng']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class RouteData {
  final String targetDestinationName;
  final String encodedPolyline;
  final int etaEpochMs;

  const RouteData({
    required this.targetDestinationName,
    required this.encodedPolyline,
    required this.etaEpochMs,
  });

  factory RouteData.fromMap(Map<String, dynamic> map) {
    return RouteData(
      targetDestinationName: (map['target_destination_name'] ?? '').toString(),
      encodedPolyline: (map['encoded_polyline'] ?? '').toString(),
      etaEpochMs: _toInt(map['eta_epoch_ms']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'target_destination_name': targetDestinationName,
      'encoded_polyline': encodedPolyline,
      'eta_epoch_ms': etaEpochMs,
    };
  }
}

class AgentMetadata {
  final String latestActionLog;
  final double financialSalvageInr;

  const AgentMetadata({
    required this.latestActionLog,
    required this.financialSalvageInr,
  });

  factory AgentMetadata.fromMap(Map<String, dynamic> map) {
    return AgentMetadata(
      latestActionLog: (map['latest_action_log'] ?? '').toString(),
      financialSalvageInr: _toDouble(map['financial_salvage_inr']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latest_action_log': latestActionLog,
      'financial_salvage_inr': financialSalvageInr,
    };
  }
}

double _toDouble(dynamic value) => (value is num) ? value.toDouble() : 0.0;

int _toInt(dynamic value) => (value is num) ? value.toInt() : 0;
