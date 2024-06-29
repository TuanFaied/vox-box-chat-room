import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:voxbox/Auth/app_state.dart';

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  late DatabaseReference _messagesRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    _messagesRef = FirebaseDatabase.instance.reference().child('rooms').child(appState.roomName!).child('messages');
  }

  void _sendMessage() {
    final appState = Provider.of<AppState>(context, listen: false);
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _messagesRef.push().set({
        'text': message,
        'sender': appState.displayName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Chat Room: ${appState.roomName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _messagesRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
                  Map data = snapshot.data!.snapshot.value as Map;
                  List messages = data.entries.map((entry) => entry.value).toList();
                  messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      return ListTile(
                        title: Text(message['sender']),
                        subtitle: Text(message['text']),
                        trailing: Text(DateTime.fromMillisecondsSinceEpoch(message['timestamp']).toLocal().toString()),
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No messages yet.'));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Enter your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}