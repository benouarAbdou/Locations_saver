import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_saver/components/categoryIcon.dart';
import 'package:location_saver/components/myButton.dart';
import 'package:location_saver/components/myTextField.dart';
import 'package:location_saver/provider/locationsProvider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class LocationsListPage extends StatefulWidget {
  const LocationsListPage({Key? key}) : super(key: key);

  @override
  _LocationsListPageState createState() => _LocationsListPageState();
}

class _LocationsListPageState extends State<LocationsListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).loadLocations();
    });
  }

  void _filterLocations(String query) {
    final locations =
        Provider.of<LocationProvider>(context, listen: false).locations;
    setState(() {
      _filteredLocations = locations
          .where((location) =>
              location['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map')),
      );
    }
  }

  Future<void> _deleteLocation(String id) async {
    try {
      await Provider.of<LocationProvider>(context, listen: false)
          .deleteLocation(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting location: $e')),
      );
    }
  }

  Future<void> _editLocation(Map<String, dynamic> location) async {
    TextEditingController nameController =
        TextEditingController(text: location['name']);
    String? selectedType = location['category'];
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
              title: const Text('Edit Location Details'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextField(
                    hintText: 'Location name',
                    icon: const Icon(Icons.place),
                    type: TextInputType.text,
                    controller: nameController,
                    errorText: 'enter the name',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
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
                  ),
                ],
              ),
              actions: [
                MyButton(
                  hint: 'Update',
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
                  function: () => Navigator.of(context).pop(false),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        await Provider.of<LocationProvider>(context, listen: false)
            .updateLocation(
          location['id'],
          nameController.text,
          selectedType ?? 'other',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to your saved locations!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search for a location",
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
                onChanged: _filterLocations,
              ),
              Expanded(
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    final locations = _filteredLocations.isEmpty &&
                            _searchController.text.isEmpty
                        ? locationProvider.locations
                        : _filteredLocations;
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(0),
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return Slidable(
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) =>
                                    _deleteLocation(location['id']),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) => _editLocation(location),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(location['name']),
                            leading: CategoryIcon(
                                category: location['category'] ?? 'other'),
                            subtitle: Text(
                                '${location['latitude'].toStringAsFixed(4)}, ${location['longitude'].toStringAsFixed(4)}'),
                            onTap: () => _openInGoogleMaps(
                                location['latitude'], location['longitude']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
