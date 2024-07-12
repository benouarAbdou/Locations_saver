import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:location_saver/pages/authPage.dart';
import 'package:location_saver/pages/mainpage.dart';
import 'package:location_saver/provider/locationsProvider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationProvider(), // Create LocationProvider here
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Locations Saver',
        theme: ThemeData(
          useMaterial3: false,
          fontFamily: 'Folks',
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLogged = false;

  void _checkCurrentUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _isLogged = true;
        });
      } else {
        setState(() {
          _isLogged = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return _isLogged ? const MainPage() : const AuthPage();
  }
}
