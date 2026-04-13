import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shipment_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ShipmentModel>> watchActiveShipments() {
    return _firestore
        .collection('ActiveShipments')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return ShipmentModel.fromDocument(doc);
            } catch (_) {
              return null;
            }
          })
          .whereType<ShipmentModel>()
          .toList(growable: false);
    });
  }
}
