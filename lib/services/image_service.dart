import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

Future<String> uploadProfileImage(String imageUrl, String userId) async {
  try {
    // Fetch the image from Google URL
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      Uint8List imageData = response.bodyBytes;

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child("profile_images/$userId.jpg");
      await ref.putData(imageData, SettableMetadata(contentType: "image/jpeg"));

      // Get and return the permanent Firebase URL
      return await ref.getDownloadURL();
    } else {
      throw Exception("Failed to fetch image");
    }
  } catch (e) {
    print("Error uploading profile image: $e");
    return "";
  }
}
