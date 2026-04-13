import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shipment_model.dart';
import '../../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final activeShipmentsProvider = StreamProvider<List<ShipmentModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchActiveShipments();
});
