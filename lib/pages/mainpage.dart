import 'package:flutter/material.dart';
import 'package:location_saver/pages/addLocation.dart';
import 'package:location_saver/pages/locationsList.dart';
import 'package:location_saver/provider/locationsProvider.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationProvider(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            LocationsListPage(),
            AddLocationPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Locations List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_location),
              label: 'Add Location',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
