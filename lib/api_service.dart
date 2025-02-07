import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fruit_grading_mobile_app/user.dart';

class ApiService {
  static const String baseUrl =
      "http://172.16.192.136:5000/"; // Use local or hosted API URL

  // Signup API
  static Future<http.Response> signup(
      String username, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    return response;
  }

  // Login API
  static Future<http.Response> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return response;
  }

  // Get Profile (Protected API)
  static Future<http.Response> validateAuthToken(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/validate"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response;
  }

  // Get Profile (Protected API)
  static Future<http.StreamedResponse> gradeImage(String imagePath) async {
    String token = User.userAuthToken;
    var request =
        http.MultipartRequest('POST', Uri.parse("$baseUrl/api/upload"));
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));
    request.headers['Authorization'] = 'Bearer $token';
    var response = await request.send();

    return response;
  }
}
