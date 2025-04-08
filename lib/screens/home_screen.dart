import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hovee_rent_chat_poc_app/services/chat_service.dart';
import 'package:hovee_rent_chat_poc_app/services/image_service.dart'
    show uploadProfileImage;
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  Future<void> startChat(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;



    var agents =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('isAvailable', isEqualTo: true)
            .limit(1)
            .get();

    if (agents.docs.isNotEmpty) {
      var agent = agents.docs.first;
      // Check if chat already exists
      var existingChat =
          await FirebaseFirestore.instance
              .collection('chats')
              .where('customerId', isEqualTo: user.uid)
              .where('agentId', isEqualTo: agent.id)
              .limit(1)
              .get();

      if (existingChat.docs.isNotEmpty) {
        String existingChatId = existingChat.docs.first.id;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(chatId: existingChatId)),
        );
        return;
      }

      // Ensure profile image exists
      String newImageUrl =
          user.photoURL != null
              ? await uploadProfileImage(user.photoURL!, user.uid)
              : '';
      String chatId = FirebaseFirestore.instance.collection('chats').doc().id;
      // String newImageUrl = await uploadProfileImage(user.photoURL!, user.uid);

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'customerId': user.uid,
        'agentId': agent.id,
        'customerName': user.displayName,
        'customerImage': newImageUrl,
        'isActive': true,
      });

      await FirebaseFirestore.instance.collection('users').doc(agent.id).update(
        {'isAvailable': false, 'assignedChatId': chatId},
      );
      await _chatService.sendNotificationToAgent(
        chatId,
        user.displayName ?? "Customer",
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No agents available")));
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${user?.displayName ?? 'Customer'}"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => startChat(context),
          child: Text("Start Chat with Agent"),
        ),
      ),
    );
  }
}
