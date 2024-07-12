import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location_saver/components/myTextField.dart';
import 'package:location_saver/pages/addLocation.dart';
import 'package:location_saver/pages/mainpage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _toggleView() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_isLogin) {
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isLogin
                  ? 'Logged in successfully'
                  : 'Signed up successfully')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Signed in with Google: ${userCredential.user!.displayName}')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } catch (e) {
      print('Error signing in with Google: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _isLogin ? 'Welcome \nBack' : 'Create \nAccount',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 30),
                  MyTextField(
                    hintText: 'Email',
                    icon: const Icon(Icons.email_rounded),
                    type: TextInputType.emailAddress,
                    errorText: 'Please enter your Email',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),
                  MyTextField(
                    hintText: 'Password',
                    icon: const Icon(Icons.lock_rounded),
                    obscure: true,
                    type: TextInputType.visiblePassword,
                    errorText: 'Please enter your Password',
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _submitForm,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2496ff),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        _isLogin ? 'Login' : 'Sign Up',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 2,
                            color: const Color(0xFF2496ff),
                          )),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.google,
                            size: 16,
                            color: Color(0xFF2496ff),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Color(0xFF2496ff),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: _toggleView,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? 'Need an account? '
                                : 'Have an account? ',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: _isLogin ? 'Sign up' : 'Log in',
                            style: const TextStyle(
                              color: Color(0xFF2496ff),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
