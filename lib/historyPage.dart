import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fruit_grading_mobile_app/db_helper.dart';
import 'package:fruit_grading_mobile_app/user.dart';
import 'package:fruit_grading_mobile_app/loginPage.dart';
import 'package:fruit_grading_mobile_app/resultPage.dart';

class HistoryView extends StatefulWidget {
  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  Future<List<Map<String, dynamic>>>? _historyRecords;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Fetch the history data from the local SQLite database
  Future<void> _fetchHistory() async {
    userId = User.userId;
    _historyRecords = DatabaseHelper.instance.getAllHistoryByUser(userId);
  }

  String _getFruitsName(List<Map<String, dynamic>> singleHistoryData){
    String result = "";
    int index = 1;
    for(var prediction in singleHistoryData){
      String fruitName = prediction['fruit'];
      result += "$index. $fruitName\n";
      index++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history available.'));
          }

          final records = snapshot.data!;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              String imagePath = record['imagePath'];
              int itemSno = index+1;
              return InkWell(
                  onTap: () {
                    List<SinglePrediction> resultViewDataList = [];
                    for(var singleResultViewData in record['data']){
                      resultViewDataList.add(SinglePrediction(id: singleResultViewData['id'], fruit: singleResultViewData['fruit'], grade: singleResultViewData['grade'], gradeVal: singleResultViewData['gradeVal'], colorAndShape: singleResultViewData['colorAndShape'], blemish: singleResultViewData['blemish']));
                    }
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ResultViewPage(imagePath: imagePath, dataList:resultViewDataList,)
                      )
                    );                  
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    elevation: 3,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Grade Prediction-$itemSno:",
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: imagePath.isNotEmpty
                                ? Image.file(File(imagePath),
                                    width: 0.95*screenWidth,
                                    height: 0.3*screenHeight,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // return Text("Image failed to load");
                                      return Icon(Icons.photo, size: 100, color: Colors.grey);
                                    },
                                  ): const Icon(Icons.image, size: 100),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Available Fruits:",
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getFruitsName(record['data']),
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: screenWidth * 0.05),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  )
                )
              );
            },
          );
        },
      ),
    );
  }
}