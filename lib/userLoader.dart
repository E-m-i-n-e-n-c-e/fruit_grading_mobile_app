import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fruit_grading_mobile_app/api_service.dart';
import 'package:fruit_grading_mobile_app/db_helper.dart';
import 'package:fruit_grading_mobile_app/user.dart';
import 'package:fruit_grading_mobile_app/loginPage.dart';
import 'package:http/http.dart';

class UserLoader extends StatelessWidget {
  const UserLoader({super.key});

  Future<void> _loadUser(BuildContext context) async {
    try {
      List<Map<String, dynamic>> result =
          await DatabaseHelper.instance.getCurrentUser();
      if (result.isEmpty) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LoginPage(),
        ));
      } else {
        Map<String, dynamic> currentUser = result[0];
        Response response =
            await ApiService.validateAuthToken(currentUser['authToken']);
        if (response.statusCode == 200) {
          User.userId = result[0]['id'];
          User.userAuthToken = result[0]['authToken'];
          User.userEmail = result[0]['email'];

          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => TransitionScreen(),
          ));
        } else if (response.statusCode == 400) {
          String message = jsonDecode(response.body)['message'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          await DatabaseHelper.instance.clearCurrentUser();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => LoginPage(),
          ));
        } else {
          int statusCode = response.statusCode;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Response status code: $statusCode")),
          );
          await DatabaseHelper.instance.clearCurrentUser();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => LoginPage(),
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User Load failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser(context); // Call the function when the body is loaded
    });
    return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            // Makes the entire Column scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(children: [Center(child: CircularProgressIndicator())]),
              ],
            ),
          ),
        ));
  }
}
