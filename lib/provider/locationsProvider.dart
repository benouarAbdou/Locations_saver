import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> get locations => _locations;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int changes = 0;

  LocationProvider() {
    loadLocations();
  }

  int getChanges() {
    return changes;
  }

  Future<void> loadLocations() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
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

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading locations: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLocation(
      double latitude, double longitude, String name, String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
    }
  }

  Future<void> updateLocation(String id, String name, String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .doc(id)
          .update({
        'name': name,
        'category': category,
      });

      final index = _locations.indexWhere((location) => location['id'] == id);
      if (index != -1) {
        _locations[index]['name'] = name;
        _locations[index]['category'] = category;
        notifyListeners();
        changes++;
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<void> deleteLocation(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .doc(id)
          .delete();

      _locations.removeWhere((location) => location['id'] == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting location: $e');
      rethrow;
    }
  }
}
