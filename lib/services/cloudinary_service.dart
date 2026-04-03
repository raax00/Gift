import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = 'your_cloud_name'; // Replace with your Cloudinary cloud name
  static const String uploadPreset = 'your_upload_preset'; // Create unsigned upload preset

  static Future<String?> uploadImage(File imageFile) async {
    try {
      var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }
}