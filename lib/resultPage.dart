import 'dart:io';

import 'package:flutter/material.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ResultViewPage(
//         imagePath: 'assets/sample.jpg', // Provide your image path
//         dataList: [
//           SinglePrediction(id:1, fruit: "Apple", grade: "A", gradeVal: 0.3, colorAndShape: 0.5, blemish: 0.8),
//           SinglePrediction(id:2, fruit: "Banana", grade: "B", gradeVal: 0.6, colorAndShape: 0.4, blemish: 0.7),
//           SinglePrediction(id:3, fruit: "Orange", grade: "C", gradeVal: 0.2, colorAndShape: 0.9, blemish: 0.3),
//         ],
//       ),
//     );
//   }
// }

// Data Model
class SinglePrediction {
  final int id;
  final String fruit;
  final String grade;
  final double gradeVal;
  final double colorAndShape;
  final double blemish;

  SinglePrediction({
    required this.id,
    required this.fruit,
    required this.grade,
    required this.gradeVal,
    required this.colorAndShape,
    required this.blemish,
  });
}

// Result View Page
class ResultViewPage extends StatelessWidget {
  final String imagePath;
  final List<SinglePrediction> dataList;

  const ResultViewPage(
      {super.key, required this.imagePath, required this.dataList});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width
    return Scaffold(
      appBar: AppBar(title: const Text("Result View")),
      body: Column(
        children: [
          // Image at the center
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.file(
              File(imagePath),
              width: screenWidth * 0.75,
              height: screenWidth * 0.75,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print(error);
                // return Text("Image failed to load");
                return Icon(Icons.photo, size: 100, color: Colors.white);
              },
            ),
          ),

          // List of special containers
          Expanded(
            child: ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                return DataContainer(index: index, data: dataList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Special Container Widget
class DataContainer extends StatefulWidget {
  final int index;
  final SinglePrediction data;

  const DataContainer({super.key, required this.index, required this.data});

  @override
  State<DataContainer> createState() => _DataContainerState();
}

class _DataContainerState extends State<DataContainer> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    double gradeVal = widget.data.gradeVal;
    double screenWidth = MediaQuery.of(context).size.width;
    double barWidth = screenWidth * 0.9;
    double pointerPosition = gradeVal * barWidth;
    pointerPosition -= (screenWidth * 0.05);
    if (gradeVal < 0.1) {
      pointerPosition += 25;
    } else if (gradeVal > 0.9) {
      pointerPosition -= 25;
    }

    Color qualityColor = valueToHsv(widget.data.gradeVal);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always visible content
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Fruit-${widget.index + 1}",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Detected Fruit: ${widget.data.fruit}",
                        style: const TextStyle(fontSize: 16)),
                    Text("Grade: ${widget.data.grade}",
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  icon: Icon(
                    isExpanded ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blue,
                  ),
                  label: Text(
                    isExpanded ? "Hide" : "See More",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Expandable content
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text("Grade in percent: ${widget.data.gradeVal}",
                  style: const TextStyle(fontSize: 16)),
              Text("Color and Shape accuracy: ${widget.data.colorAndShape}",
                  style: const TextStyle(fontSize: 16)),
              Text("Good texture Percentage: ${widget.data.blemish}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),

              // HSV Color Gradient Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quality Grade",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),

                  // Progress Bar with Gradient
                  Center(
                    child: Stack(
                      children: [
                        // Gradient Bar
                        Container(
                          width: barWidth,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: generateHSVGradient(
                                  Colors.red, Colors.green, 11),
                              stops: List.generate(11, (i) => i / 10),
                            ),
                          ),
                        ),
                        // Pointer Indicator
                        Positioned(
                          left: pointerPosition,
                          child: Container(
                            width: 8,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Poor - Excellent Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Poor",
                          style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 65, 64, 64))),
                      Text("Excellent",
                          style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 65, 64, 64))),
                    ],
                  ),

                  // Quality Label & Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Excellent Quality",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        widget.data.gradeVal.toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: qualityColor),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }
}

// Function to Generate an HSV Gradient
List<Color> generateHSVGradient(Color start, Color end, int steps) {
  return List.generate(steps, (index) {
    double t = index / (steps - 1); // Normalize to range 0-1
    return HSVColor.lerp(HSVColor.fromColor(start), HSVColor.fromColor(end), t)!
        .toColor();
  });
}

Color valueToHsv(double value) {
  double hue = value * 120; // Map value [0, 1] to hue [0, 120] (Red to Green)
  double saturation = 1.0; // Full saturation
  double brightness = 1.0; // Full brightness

  HSVColor hsvColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness);
  return hsvColor.toColor(); // Convert to RGB
}
