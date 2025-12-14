// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> uploadAndEncryptFile(
  FFUploadedFile? fileToUpload,
) async {
  if (fileToUpload == null) {
    print("No file selected.");
    return;
  }

  // This is the IP address for your Flask API
  const String apiUrl = "http://10.0.2.2:5000/encrypt_file";

  try {
    // 1. Create a "Multipart" request, which is used for files
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // 2. Add the file to the request
    // 'file' is the key that your Python API is expecting
    request.files.add(
      http.MultipartFile.fromBytes(
        'file', // This MUST match the key in your Flask code
        fileToUpload.bytes!,
        filename: fileToUpload.name,
      ),
    );

    // 3. Send the request
    var response = await request.send();

    // 4. Get the response
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print("File upload successful!");
      print("Server response: $responseBody");
      // You could show a "Success" snackbar here
    } else {
      final responseBody = await response.stream.bytesToString();
      print("File upload failed.");
      print("Server response: $responseBody");
      // You could show an "Error" snackbar here
    }
  } catch (e) {
    print("An error occurred: $e");
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
