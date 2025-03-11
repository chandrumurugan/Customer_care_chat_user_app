import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getAvailableAgentToken() async {
    QuerySnapshot agents = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .where('isAvailable', isEqualTo: true)
        .limit(1)
        .get();

    if (agents.docs.isNotEmpty) {
      return agents.docs.first['fcmToken'];
    }
    return null;
  }

  Future<void> sendNotificationToAgent(String chatId, String customerName) async {
    String? agentToken = await getAvailableAgentToken();

    if (agentToken != null) {
      final String serverKey =
          'YOUR_SERVER_KEY_HERE'; // Get this from Firebase Console

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      var body = jsonEncode({
        "to": agentToken,
        "notification": {
          "title": "New Customer Chat",
          "body": "$customerName has started a chat with you",
        },
        "data": {
          "chatId": chatId,
        }
      });

      var response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully");
      } else {
        print("Error sending notification: ${response.body}");
      }
    }
  }
}
