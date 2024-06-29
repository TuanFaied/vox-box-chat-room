import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:voxbox/Auth/app_state.dart';
import 'package:voxbox/constants.dart';

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late CollectionReference _messagesRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    _messagesRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(appState.roomName!)
        .collection('messages');
  }

  void _sendMessage(types.PartialText message) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.user != null) {
      _messagesRef.add({
        'text': message.text,
        'sender': appState.user!.displayName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': appState.user!.uid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = types.User(
      id: appState.userId ?? '',
      firstName: appState.displayName ?? '',
    );

    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              '${appState.roomName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _messagesRef.orderBy('timestamp').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('An error occurred: ${snapshot.error}'));
                    }

                    List<types.Message> messages =
                        snapshot.data!.docs.reversed.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // Handle missing or null fields
                      final text = data['text'] as String? ?? 'No text';
                      final senderName = data['sender'] as String? ?? 'Anonymous';
                      final userId = data['userId'] as String? ?? '';
                      final timestamp = data['timestamp'] as int? ?? 0;

                      final author = types.User(
                        id: userId,
                        firstName: senderName,
                      );

                      return types.TextMessage(
                        author: author,
                        createdAt: timestamp,
                        id: doc.id,
                        text: text,
                      );
                    }).toList();

                    return chat_ui.Chat(
                      scrollPhysics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      messages: messages,
                      onSendPressed: _sendMessage,
                      user: user,
                      showUserNames: true,
                      showUserAvatars: true,
                      theme: chat_ui.DefaultChatTheme(
                        inputBackgroundColor: Colors.grey,
                        inputBorderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                          right: Radius.circular(10),
                        ),
                        sendButtonIcon: Icon(
                          Icons.send,
                          color: kPrimaryColor,
                        ),
                        

                      ),
                      
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
