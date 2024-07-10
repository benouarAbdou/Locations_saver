import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:location_saver/pages/authPage.dart';

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

  // You need to replace this with your actual API key
  final String apiKey = 'AIzaSyC3EnwU_NsCmWwPavSy7hnk-PYE_zdQ0hY';

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(apiKey);
    _checkLocationPermission();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

  void _addMarker() async {
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
      const SnackBar(content: Text('Location is disabled')),
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
      appBar: AppBar(
        title: const Text('Add Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: initialCameraPosition,
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onCameraMove: (CameraPosition position) {
                    _currentCameraPosition = position.target;
                  },
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    color: Colors.white,
                    child: const Column(
                      children: [
                        /*TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search for a place',
                            suffixIcon: Icon(Icons.search),
                          ),
                          onChanged: _autocomplete,
                        ),
                        if (_predictions.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _predictions.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_predictions[index].description!),
                                  onTap: () =>
                                      _selectPlace(_predictions[index]),
                                );
                              },
                            ),
                          ),*/
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.add_location, color: Colors.red),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMarker,
        child: const Icon(Icons.add_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
