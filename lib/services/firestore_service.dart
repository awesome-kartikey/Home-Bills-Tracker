import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  FirestoreService({required this.userId});

  // Tenants
  Stream<List<Tenant>> getTenants() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tenants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tenant.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addTenant(Tenant tenant) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tenants')
        .add(tenant.toMap());
  }

  Future<void> updateTenant(Tenant tenant) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tenants')
        .doc(tenant.id)
        .update(tenant.toMap());
  }

  Future<void> deleteTenant(String tenantId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tenants')
        .doc(tenantId)
        .delete();
  }

  // Bills
  Stream<List<Bill>> getBills() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bills')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bill.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addBill(Bill bill) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bills')
        .add(bill.toMap());
  }

  // Milk
  Stream<MilkDoc?> getMilkDoc() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('milk')
        .doc('main')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return MilkDoc.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  Future<void> updateMilkDay(String date, List<double> quantities) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('milk')
        .doc('main')
        .set({
      'days': {date: quantities}
    }, SetOptions(merge: true));
  }

  // Settings
  Stream<GlobalSettings> getSettings() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('global')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return GlobalSettings.fromMap(snapshot.data()!);
      }
      return GlobalSettings(electricityRate: 0, milkRate: 0);
    });
  }

  Future<void> updateSettings(GlobalSettings settings) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('global')
        .set(settings.toMap());
  }
}
