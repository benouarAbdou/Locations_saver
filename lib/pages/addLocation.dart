import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_saver/components/myButton.dart';
import 'package:location_saver/components/myTextField.dart';
import 'package:location_saver/pages/authPage.dart';
import 'package:location_saver/provider/locationsProvider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

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
  List<Map<String, dynamic>> _placesList = [];
  Timer? _debounce;

  int changes = LocationProvider().getChanges();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placesList = [];
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 2000), () async {
      try {
        final response = await http.get(
          Uri.parse(
              'https://nominatim.openstreetmap.org/search?format=json&q=$query'),
          headers: {
            'User-Agent':
                'locationsSaver/1.0', // Replace with your app name and version
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> places = json.decode(response.body);
          setState(() {
            _placesList =
                places.map((place) => place as Map<String, dynamic>).toList();
          });
        } else {
          _showErrorDialog(
              'Failed to fetch place suggestions. Status: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('Error fetching place suggestions: $e');
      }
    });
  }

  void _selectPlace(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    mapController
        .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), 15));
    setState(() {
      _searchController.text = place['display_name'];
      _placesList = [];
    });
  }

  void _handleSearch() {
    final input = _searchController.text;
    final coordinates = input.split(',');
    if (coordinates.length == 2) {
      _goToCoordinates();
    } else {
      _searchPlaces(input);
    }
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
    BitmapDescriptor markerIcon =
        await getMarkerIconForCategory(selectedType ?? 'other');

    /*setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(_currentCameraPosition.toString()),
          position: _currentCameraPosition,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: nameController.text,
            snippet:
                '${_currentCameraPosition.latitude}, ${_currentCameraPosition.longitude} - ${selectedType ?? 'other'}',
          ),
        ),
      );
    });*/

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

  Future<BitmapDescriptor> getMarkerIconForCategory(String category) async {
    String assetName;
    switch (category) {
      case 'work':
        assetName = 'assets/blueMarkerExtra.png';
        break;
      case 'food':
        assetName = 'assets/goldMarker.png';
        break;
      case 'travel':
        assetName = 'assets/greenMarker.png';
        break;
      case 'family':
        assetName = 'assets/purpleMarker.png';
        break;
      case 'friends':
        assetName = 'assets/redMarker.png';
        break;
      case 'other':
      default:
        assetName = 'assets/greyMarker.png';
        break;
    }

    final Uint8List markerIcon = await getBytesFromAsset(assetName, 125);
    return BitmapDescriptor.fromBytes(markerIcon);
  }

  Future<void> _loadUserMarkers() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.loadLocations();
    _updateMarkers();
  }

  Future<void> _updateMarkers() async {
    final locations =
        Provider.of<LocationProvider>(context, listen: false).locations;
    final Set<Marker> newMarkers = {};

    for (var location in locations) {
      final BitmapDescriptor markerIcon =
          await getMarkerIconForCategory(location['category']);
      newMarkers.add(Marker(
        markerId: MarkerId(location['id']),
        position: LatLng(location['latitude'], location['longitude']),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: location['name'],
          snippet:
              '${location['latitude'].toStringAsFixed(2)}, ${location['longitude'].toStringAsFixed(2)} - ${location['category']}',
        ),
      ));
    }

    setState(() {
      markers.clear();
      markers.addAll(newMarkers);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
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
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.locations.length != markers.length ||
              changes != locationProvider.changes) {
            changes = locationProvider.changes;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _updateMarkers());
          }
          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: initialCameraPosition,
                markers: markers,
                myLocationEnabled: true,
                compassEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onCameraMove: (CameraPosition position) {
                  _currentCameraPosition = position.target;
                },
              ),
              const Center(
                child: Icon(Icons.place, color: Colors.red),
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
                              hintText: "Search place or enter coordinates",
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFFf0f5fe),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _placesList.clear();
                                  });
                                },
                                child: const Icon(Icons.clear),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20.0, horizontal: 20.0),
                            ),
                            onChanged: (value) => _searchPlaces(value),
                            onSubmitted: (_) => _handleSearch(),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFf0f5fe),
                          ),
                          child: IconButton(
                            color: Colors.grey,
                            icon: const Icon(Icons.search),
                            onPressed: _handleSearch,
                          ),
                        ),
                      ],
                    ),
                    if (_placesList.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xFFf0f5fe),
                            borderRadius: BorderRadius.circular(10)),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(0),
                          shrinkWrap: true,
                          itemCount: _placesList.length,
                          itemBuilder: (context, index) {
                            final place = _placesList[index];
                            return ListTile(
                              title: Text(place['display_name']),
                              onTap: () => _selectPlace(place),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMarker,
        child: const Icon(Icons.place),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
