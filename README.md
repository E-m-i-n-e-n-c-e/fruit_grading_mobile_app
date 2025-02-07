# Fruit Grading Mobile App

A Flutter mobile application for grading fruits using image processing and machine learning.

## Prerequisites

- Flutter SDK installed
- Android Studio / VS Code with Flutter extensions
- Physical Android device or Emulator for testing
- Backend server running 

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone [your-repository-url]
   cd fruit_grading_mobile_app
   ```

2. **Install Dependencies**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Configure Server IP Address**
   - Open `lib/api_service.dart`
   - Locate the `baseUrl` variable
   - Change the IP address according to your setup:
     - For physical device: Use your server's IP address (e.g., "http://192.168.1.100:5000")
     - For Android Emulator: Use "http://10.0.2.2:5000" (This maps to localhost)
   ```dart
   static const String baseUrl = "http://YOUR_SERVER_IP:5000";
   ```

4. **Server Configuration**
   - Ensure your server is running
   - Disable firewall on the server machine or configure it to allow incoming connections
   - Test the server connection before running the app

## Building and Running

### Development Build
```bash
flutter run
```

### Release Build
```bash
flutter build apk --release
```
The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

## Common Issues

1. **Server Connection Failed**
   - Verify server IP address is correct
   - Check if server is running
   - Ensure firewall is not blocking connections

2. **Build Errors**
   - Run `flutter clean` before rebuilding
   - Ensure all dependencies are properly installed
   - Check if the Android SDK is properly configured





 
