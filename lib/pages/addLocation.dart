import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_saver/components/myTextField.dart';
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

    TextEditingController nameController = TextEditingController();
    String? selectedType;
    List<String> types = [
      'work',
      'food',
      'travel',
      'family',
      'friends',
      'other'
    ];
    String nameError = "";

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              actionsAlignment: MainAxisAlignment.center,
              title: const Text('Add Location Details'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextField(
                    hintText: 'Location name',
                    icon: const Icon(Icons.place),
                    type: TextInputType.text,
                    controller: nameController,
                    errorText: '',
                  ),
                  const SizedBox(height: 5),
                  nameError.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          nameError,
                          textAlign: TextAlign.left,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    hint: const Text('Select category'),
                    items: types.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Select type",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFf0f5fe),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 20.0),
                      prefixIcon: const Icon(Icons.category),
                    ),
                  ),
                ],
              ),
              actions: [
                MyButton(
                  hint: 'Add',
                  function: () {
                    if (nameController.text.isEmpty) {
                      setState(() {
                        nameError = 'Please enter a name';
                      });
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
                MyButton(
                  hint: 'Cancel',
                  function: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return; // User cancelled or closed the dialog
    }

    if (nameController.text.isEmpty) {
      _showErrorDialog('Please enter a name.');
      return;
    }

    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(_currentCameraPosition.toString()),
          position: _currentCameraPosition,
          infoWindow: InfoWindow(
            title: nameController.text,
            snippet:
                '${_currentCameraPosition.latitude}, ${_currentCameraPosition.longitude} - ${selectedType ?? 'other'}',
          ),
        ),
      );
    });

    try {
      await Provider.of<LocationProvider>(context, listen: false).addLocation(
        _currentCameraPosition.latitude,
        _currentCameraPosition.longitude,
        nameController.text,
        selectedType ?? 'other',
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
            title: data['name'],
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

  void _goToCoordinates() {
    final input = _searchController.text;
    final coordinates = input.split(',');
    if (coordinates.length == 2) {
      final lat = double.tryParse(coordinates[0]);
      final lng = double.tryParse(coordinates[1]);
      if (lat != null && lng != null) {
        mapController
            .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
        setState(() {
          _searchController.clear();
        });
      } else {
        _showErrorDialog('Invalid coordinates format.');
      }
    } else {
      _showErrorDialog('Invalid coordinates format.');
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Enter coordinates (lat,lng)",
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFf0f5fe),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 20.0),
                            prefixIcon: const Icon(Icons.place),
                          ),
                          onSubmitted: (_) => _goToCoordinates(),
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

class MyButton extends StatelessWidget {
  final String hint;
  final Function function;
  const MyButton({
    super.key,
    required this.hint,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => function(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2496ff),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(hint),
    );
  }
}
