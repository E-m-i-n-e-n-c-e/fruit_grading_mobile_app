import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fruit_grading_mobile_app/db_helper.dart';  // Import your database helper

class Grade {
  // Function to download an image and save it locally
  static Future<Map<String, dynamic>?> performGrading(String url, int userId) async {
    try {
      // Send HTTP POST request to fetch the image
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get the temporary directory
        Directory directory = await getApplicationDocumentsDirectory();
        
        // Create a file path
        String fileName = "image_${DateTime.now().millisecondsSinceEpoch}.png";
        String filePath = "${directory.path}/Fruit Grading/$fileName";
        
        // Save the file
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if(response.headers.containsKey('json_data')){
          String? jsonData = response.headers['json_data'];
          if(jsonData!.isNotEmpty){
            List<Map<String, dynamic>> jsonParseData = json.decode(jsonData);
            List<Map<String, dynamic>> predictions = [];
            for(var singleData in jsonParseData){
              Map<String, dynamic> data = {'fruit': singleData['fruit_name'], 'grade': singleData['grade'], 'gradeVal': singleData['grade_val'], 'colorandshape': singleData['color_shape_acc'], 'blemish': singleData['color_shape_acc'], 'coordsList': singleData['bounded_box_co_ordinates']};
              predictions.add(data);
            }
            int? id = await DatabaseHelper.instance.addHistoryWithPredictions(filePath, userId, predictions);
            if(id == null){
              return null;
            }
            Map<String, dynamic>? historyData = await DatabaseHelper.instance.getHistoryById(id);
            if(historyData == null){
              return null;
            }
            return historyData;
          }          
        }

        // Insert the saved image path into history table
        // await DatabaseHelper.instance.insertHistory(userId, predictes, filePath);

        return null; // Return the saved file path
      } else {
        print("Failed to download image. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error downloading image: $e");
      return null;
    }
  }
}
