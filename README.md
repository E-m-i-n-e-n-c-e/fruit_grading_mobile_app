1. IMPORTANT: run "flutter clean" as 1st comment, some dependencies won't match with your pc, you need to clear it, when you install "flutter pub get", dependencies will installed as per you pc

2. run the command to install the dependencies
flutter pub get

3. change the server ip in ".\lib\apiService.dart"
in line 6 => apiService.dart

4. make sure that "firewall" of the server machine is "off"
if firewall on, then it won't app to communicate server. so we need to off the fire wall

5. to get only apk
flutter build apk

you will find the apk in folder ".\build\app\outputs\flutter-apk\app-release.apk"

ended.......

6. to run flutter with debug:(connect a developer option enabled device or mobile using usb)
flutter run


<!-- # fruit_grading_mobile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference. -->
