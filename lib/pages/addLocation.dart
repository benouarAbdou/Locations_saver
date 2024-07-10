import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_saver/pages/authPage.dart';
import 'package:location_saver/provider/locationsProvider.dart';
import 'package:provider/provider.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({Key? key}) : super(key: key);

  @override
  _AddLocationPageState createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<AutocompletePrediction> _predictions = [];
  late GooglePlace googlePlace;
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 2,
  );
  late LatLng _currentCameraPosition;
  bool _isLoading = true;

  final String apiKey = 'AIzaSyC3EnwU_NsCmWwPavSy7hnk-PYE_zdQ0hY';

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(apiKey);
    _checkLocationPermission();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadUserMarkers();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied.');
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog('Location permissions are permanently denied.');
      setState(() => _isLoading = false);
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        initialCameraPosition = const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        );
        _isLoading = false;
      });
      _showErrorDialog('Location services are disabled.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        initialCameraPosition = const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        );
        _isLoading = false;
      });
      _showErrorDialog('Failed to get current location.');
    }
  }

  Future<void> _addMarker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('User not signed in.');
      return;
    }

    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(_currentCameraPosition.toString()),
          position: _currentCameraPosition,
          infoWindow: InfoWindow(
            title: 'Added Location',
            snippet:
                '${_currentCameraPosition.latitude}, ${_currentCameraPosition.longitude}',
          ),
        ),
      );
    });

    try {
      await Provider.of<LocationProvider>(context, listen: false).addLocation(
        _currentCameraPosition.latitude,
        _currentCameraPosition.longitude,
      );
    } catch (e) {
      print('Error adding marker: $e');
      _showErrorDialog('Failed to add marker.');
    }
  }

  Future<void> _loadUserMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('User not signed in.');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .get();
      final userMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        final geoPoint = data['position'] as GeoPoint;
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          infoWindow: InfoWindow(
            title: 'Saved Location',
            snippet: '${geoPoint.latitude}, ${geoPoint.longitude}',
          ),
        );
      }).toSet();

      setState(() {
        markers.addAll(userMarkers);
      });
    } catch (e) {
      print('Error loading markers from Firestore: $e');
    }
  }

  void _autocomplete(String input) async {
    if (input.isNotEmpty) {
      final result = await googlePlace.autocomplete.get(input);
      if (result != null && result.predictions != null) {
        setState(() {
          _predictions = result.predictions!;
        });
      }
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _selectPlace(AutocompletePrediction prediction) async {
    final details = await googlePlace.details.get(prediction.placeId!);
    if (details != null &&
        details.result != null &&
        details.result!.geometry != null) {
      final lat = details.result!.geometry!.location!.lat;
      final lng = details.result!.geometry!.location!.lng;
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat!, lng!), 15));
      setState(() {
        _predictions = [];
        _searchController.text = prediction.description!;
      });
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: initialCameraPosition,
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onCameraMove: (CameraPosition position) {
                    _currentCameraPosition = position.target;
                  },
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "search a place",
                                hintStyle: const TextStyle(
                                    color: Colors.grey), // Hint text color
                                filled: true, // To make the background filled
                                fillColor:
                                    const Color(0xFFf0f5fe), // Background color
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Rounded corners
                                  borderSide: BorderSide.none, // No border
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 20.0,
                                    horizontal:
                                        20.0), // Padding inside the field
                                prefixIcon: const Icon(
                                    Icons.place), // Icon inside the field
                              ),
                              onChanged: _autocomplete,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFf0f5fe),
                            ),
                            child: IconButton(
                              color: Colors.grey,
                              icon: const Icon(Icons.logout),
                              onPressed: _signOut,
                            ),
                          ),
                        ],
                      ),
                      if (_predictions.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _predictions.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_predictions[index].description!),
                                onTap: () => _selectPlace(_predictions[index]),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const Center(
                  child: Icon(Icons.place, color: Colors.red),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMarker,
        child: const Icon(Icons.place),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
