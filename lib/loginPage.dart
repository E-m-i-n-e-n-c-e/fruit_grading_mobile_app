import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:fruit_grading_mobile_app/main.dart';
import 'package:fruit_grading_mobile_app/db_helper.dart';
import 'package:fruit_grading_mobile_app/api_service.dart';
import 'package:fruit_grading_mobile_app/user.dart';

int userId = 0;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoginPage = true;
  bool _obscureText = true;

  void toggleIsLoginPage() {
    setState(() {
      _isLoginPage = !_isLoginPage;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _signin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    try {
      http.Response response = await ApiService.signup(name, email, password);
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      int responseStatus = response.statusCode;
      if (responseStatus == 200) {
        User.userId = responseBody['id'];
        User.userAuthToken = responseBody['access_token'];
        User.userEmail = responseBody['email'];
        await DatabaseHelper.instance
            .insertCurrentUser(User.userId, User.userAuthToken, User.userEmail);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => TransitionScreen(),
        ));
      } else if (responseStatus == 400) {
        String message = responseBody['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to signin: $message')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Response Status Code: $responseStatus')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to signin: $e')),
      );
    }
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      http.Response response = await ApiService.login(email, password);
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      int responseStatus = response.statusCode;
      if (responseStatus == 200) {
        User.userId = responseBody['id'];
        User.userAuthToken = responseBody['access_token'];
        User.userEmail = responseBody['email'];
        await DatabaseHelper.instance
            .insertCurrentUser(User.userId, User.userAuthToken, User.userEmail);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => TransitionScreen(),
        ));
      } else if (responseStatus == 400) {
        String message = responseBody['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to login: $message')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Response Status Code: $responseStatus')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to signin: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 155, 214, 243), // Soft light green background
      appBar: AppBar(title: Text('Fruit Detection')),
      body: SingleChildScrollView(
        // Makes the entire Column scrollable
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/login.jpg'), // Add your image here
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Adding a semi-transparent overlay
              Opacity(
                opacity: 0.3, // Adjust the opacity value as needed (0.0 to 1.0)
                child: Container(
                  color: Colors.black, // Dark overlay to give more contrast
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Add the image above the phone number field
                    Image.asset(
                      'assets/logo.png', // Replace with the path to your image
                      height: 200, // Adjust the height as needed
                    ),
                    SizedBox(height: 100),
                    if (!_isLoginPage)
                      TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor:
                              Colors.white70, // Makes the text fields readable
                        ),
                      ),

                    if (!_isLoginPage)
                      Container(
                        height: 20, // Adds 20px vertical space
                      ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email: ',
                        hintText: 'Enter Email id',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor:
                            Colors.white70, // Makes the text fields readable
                      ),
                    ),
                    Container(
                      height: 20, // Adds 20px vertical space
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText:
                          _obscureText, // Toggles visibility of password
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        hintText: 'Enter Password',
                        filled: true,
                        fillColor:
                            Colors.white70, // Makes the text fields readable
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText =
                                  !_obscureText; // Toggle password visibility
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoginPage ? _login : _signin,
                      child: Text('Submit'),
                    ),
                    ElevatedButton(
                      onPressed: toggleIsLoginPage,
                      child: Text(_isLoginPage ? 'Sign up?' : 'Log in?'),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome to the Home Screen!')),
    );
  }
}

class TransitionScreen extends StatefulWidget {
  const TransitionScreen({super.key});

  @override
  _TransitionScreenState createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to ContentView after a delay
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ContentView()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 186, 248, 114), // Soft light green background
      body: Center(
        child: SingleChildScrollView(
          // Makes the entire Column scrollable
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png', // Replace with your image path
                height: 800,
                width: 800,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Please wait...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Dark color for readability
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
