
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue, FirebaseFirestore;

class DBservices{
  Future<void> addUser(String userId, String name, String role, {bool isAvailable = false}) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).set({
    'name': name,
    'role': role, // 'customer' or 'agent'
    'isAvailable': role == 'agent' ? isAvailable : null, // Only for agents
    'assignedChatId': null, // Default null
  });
}

Future<void> createChat(String chatId, String customerId, String agentId) async {
  await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
    'customerId': customerId,
    'agentId': agentId,
    'isActive': true, // Chat is active by default
  });

  // Update agent’s assigned chat
  await FirebaseFirestore.instance.collection('users').doc(agentId).update({
    'assignedChatId': chatId,
    'isAvailable': false, // Mark agent as unavailable
  });
}

Future<void> sendMessage(String chatId, String senderId, String message) async {
  await FirebaseFirestore.instance
      .collection('messages')
      .doc(chatId)
      .collection('messages')
      .add({
    'senderId': senderId,
    'message': message,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Future<void> closeChat(String chatId, String agentId) async {
  await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
    'isActive': false, // Chat is closed
  });

  // Free up the agent
  await FirebaseFirestore.instance.collection('users').doc(agentId).update({
    'assignedChatId': null,
    'isAvailable': true,
  });
}




}