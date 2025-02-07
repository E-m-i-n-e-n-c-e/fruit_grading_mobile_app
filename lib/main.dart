import 'package:flutter/material.dart';
import 'package:fruit_grading_mobile_app/api_service.dart';
import 'package:fruit_grading_mobile_app/resultPage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:fruit_grading_mobile_app/db_helper.dart';
import 'package:fruit_grading_mobile_app/user.dart';
import 'package:fruit_grading_mobile_app/userLoader.dart';
import 'package:fruit_grading_mobile_app/loginPage.dart';
import 'package:fruit_grading_mobile_app/historyPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Email Login',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Color.fromRGBO(160, 159, 159, 1)),
      // home: ContentView(),r
      home: UserLoader(),
    );
  }
}

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  _ContentViewState createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 0; // Tracks the selected tab

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _navigateToResult(BuildContext context) {
    if (_selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultView(image: _selectedImage!),
        ),
      );
    }
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    setState(() {
      _selectedIndex = index;
    });

    // Call respective functions based on the selected index
    if (_selectedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ContentView()),
      );
    } else if (_selectedIndex == 1) {
      //history
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryView()),
      );
    } else if (_selectedIndex == 2) {
      // logout
      await DatabaseHelper.instance.clearCurrentUser();
      User.clearUser();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fruit Grading')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            "assets/back.png", // Ensure you have this image in your assets folder
            fit: BoxFit.cover,
          ),

          // Centered UI Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keeps the layout compact
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _selectedImage != null
                      ? Image.file(_selectedImage!,
                          height: 300, fit: BoxFit.cover)
                      : Icon(Icons.photo, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.photo_library),
                        label: Text("Choose Photo"),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.camera_alt),
                        label: Text("Take Photo"),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_selectedImage != null)
                    ElevatedButton(
                      onPressed: () => _navigateToResult(context),
                      child: Text("Grade"),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Main",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Log out",
          ),
        ],
      ),
    );
  }
}

class ResultView extends StatefulWidget {
  final File image;

  const ResultView({super.key, required this.image});

  @override
  _ResultViewState createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  String? _result;
  String? _outputImagePath;
  bool _isResultVisible = false;
  final double _gradePercent = 0; // To hold the grade percentage

  @override
  void initState() {
    super.initState();
    _uploadImage();
  }

  Future<void> _uploadImage() async {
    try {
      // http.StreamedResponse response = await ApiService.gradeImage(widget.image.path);
      String token = User.userAuthToken;
      String baseUrl = ApiService.baseUrl;
      var request =
          http.MultipartRequest('POST', Uri.parse("$baseUrl/api/upload"));
      request.files
          .add(await http.MultipartFile.fromPath('file', widget.image.path));
      request.headers['Authorization'] = 'Bearer $token';
      var response = await request.send();

      if (response.statusCode != 200) {
        Navigator.of(context).pop();
      } else if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();

        Directory? directory;
        if (Platform.isAndroid) {
          directory =
              await getExternalStorageDirectory(); // App's external storage
        } else {
          directory = await getApplicationDocumentsDirectory(); // iOS
        }

        if (directory == null) {
          print("Error: Directory is null");
          return;
        }

        String folderPath = '${directory.path}/Fruit Grading';
        await Directory(folderPath).create(recursive: true);

        String fileName = "image_${DateTime.now().millisecondsSinceEpoch}.png";
        String filePath = "$folderPath/$fileName";

        File file = File(filePath);
        await file.writeAsBytes(responseData);

        print("Image saved at: $filePath");

        int userId = User.userId;
        if (userId <= 0) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => LoginPage(),
          ));
        }

        if (response.headers.containsKey('json_data')) {
          String? jsonData = response.headers['json_data'];
          // print(jsonData);
          if (jsonData!.isNotEmpty) {
            List<Map<String, dynamic>> jsonParseData =
                List<Map<String, dynamic>>.from(json.decode(jsonData));
            // print(jsonParseData);
            List<Map<String, dynamic>> predictions = [];
            for (var singleData in jsonParseData) {
              Map<String, dynamic> data = {
                'fruit': singleData['fruit_name'],
                'grade': singleData['grade'],
                'gradeVal': singleData['grade_val'],
                'colorandshape': singleData['color_shape_acc'],
                'blemish': singleData['color_shape_acc'],
                'coordsList': singleData['bounded_box_co_ordinates']
              };
              predictions.add(data);
            }
            int? id = await DatabaseHelper.instance
                .addHistoryWithPredictions(filePath, userId, predictions);
            if (id == null) {
              return;
            } else {
              print(id);
            }

            Map<String, dynamic>? historyData =
                await DatabaseHelper.instance.getHistoryById(id);
            if (historyData == null) {
              return;
            }
            final resultText = _extractResultFromSingleHistory(historyData);
            // final resultText = _extractResultFromSingleHistory({'imagePath': filePath, 'data': predictions});
            List<SinglePrediction> resultViewDataList = [];
            for (var singleResultViewData in historyData['data']) {
              resultViewDataList.add(SinglePrediction(
                  id: singleResultViewData['id'],
                  fruit: singleResultViewData['fruit'],
                  grade: singleResultViewData['grade'],
                  gradeVal: singleResultViewData['gradeVal'],
                  colorAndShape: singleResultViewData['colorAndShape'],
                  blemish: singleResultViewData['blemish']));
            }
            setState(() {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => ResultViewPage(
                        imagePath: historyData['imagePath'],
                        dataList: resultViewDataList,
                      )));
              // _result = resultText;
              // _outputImagePath = historyData['photo_path'];
              // _outputImagePath = filePath;
              // _gradePercent = _extractGradePercent(
              // historyData); // Extract and convert grade percent
            });
          }
        }
      }

      // Insert the saved image path into history table
      // await DatabaseHelper.instance.insertHistory(userId, predictes, filePath);
    } catch (e) {
      setState(() {
        _result = "Upload failed: $e";
      });
    }
  }

  String _extractResultFromSingleHistory(Map<String, dynamic> historyData) {
    if (historyData['data'].isEmpty) {
      return '';
    } else {
      int index = 0;
      String returnData = "";
      for (var singlePredictionData in historyData['data']) {
        index++;
        String? fruit = singlePredictionData['fruit'];
        String? grade = singlePredictionData['grade'];
        String? gradeVal = singlePredictionData['gradeVal'].toString();
        String? colorandshape =
            singlePredictionData['colorandshape'].toString();
        String? blemish = singlePredictionData['blemish'].toString();
        returnData += '''

          Fruit id: $index
          Detected Fruit: $fruit
          Grade: $grade
          Grade in percent: $gradeVal
          Color and Shape accuracy: $colorandshape
          Good texture Percentage: $blemish

        ''';
        // returnData += '''

        //   Fruit id: $index
        //   Detected Fruit: $singlePredictionData['fruit']
        //   Grade: $singlePredictionData['fruit']
        //   Grade in percent: $singlePredictionData['gradeval']
        //   Color and Shape accuracy: $singlePredictionData['colorandshape']
        //   Good texture Percentage: $singlePredictionData['blemish']

        // ''';
      }
      return returnData;
    }
  }

  // // Extract grade percent and convert to 0-100 scale
  // double _extractGradePercent(String html) {
  //   final percentRegExp = RegExp(r'<p>Grade in percent: (.*?)</p>');
  //   final gradePercent = percentRegExp.firstMatch(html)?.group(1) ?? '0.0';
  //   return double.tryParse(gradePercent) ?? 0.0;
  // }

  // // Get color based on grade percent
  // Color _getGradeColor(double gradePercent) {
  //   if (gradePercent < 40) {
  //     return Colors.red;
  //   } else if (gradePercent >= 40 && gradePercent < 60) {
  //     return Colors.orange;
  //   } else {
  //     return Colors.green;
  //   }
  // }

  void _showResultDetails() {
    setState(() {
      _isResultVisible = !_isResultVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Makes the entire Column scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  if (_outputImagePath != null)
                    Center(
                        child: Image.file(
                      File(_outputImagePath!),
                      height: 300,
                      fit: BoxFit.cover,
                    ))
                  else
                    Center(child: CircularProgressIndicator()),
                  if (_outputImagePath != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                          ),
                        ),
                        onPressed:
                            _showResultDetails, // Your action when tapped
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Add other widgets here

              // Grade percentage bar
              if (_gradePercent != 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quality Grade",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar with Gradient
                    Stack(
                      children: [
                        // Gradient Bar
                        Container(
                          width: 400, // Set width to match pointer calculations
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.orange, Colors.green],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        // Pointer Indicator (Now accurately positioned)
                        Positioned(
                          right: (_gradePercent *
                              100), // Adjust based on bar width
                          child: Container(
                            width: 8,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Quality Label & Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Excellent Quality",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                          _gradePercent.toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),

                    // Poor - Excellent Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Poor",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text("Excellent",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Display result text after info button tap
              if (_isResultVisible && _result != null)
                Text(
                  _result!,
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
