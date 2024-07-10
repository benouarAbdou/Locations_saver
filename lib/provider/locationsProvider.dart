import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> get locations => _locations;

  Future<void> loadLocations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case where the user is not signed in
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .get();

      _locations = snapshot.docs.map((doc) {
        final data = doc.data();
        final geoPoint = data['position'] as GeoPoint;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Location',
          'latitude': geoPoint.latitude,
          'longitude': geoPoint.longitude,
          'category': data['category'] ?? 'other',
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error loading locations: $e');
      // Handle the error (e.g., show a snackbar)
    }
  }

  Future<void> addLocation(
      double latitude, double longitude, String name, String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case where the user is not signed in
      return;
    }

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .add({
        'position': GeoPoint(latitude, longitude),
        'name': name,
        'category': category,
      });

      _locations.add({
        'id': docRef.id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
      });

      notifyListeners();
    } catch (e) {
      print('Error adding location: $e');
      // Handle the error (e.g., show a snackbar)
    }
  }
}
