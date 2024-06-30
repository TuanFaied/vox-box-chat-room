import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:voxbox/Auth/app_state.dart';
import 'package:voxbox/constants.dart';
import 'package:intl/intl.dart';



class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late CollectionReference _messagesRef;
  final TextEditingController _textController = TextEditingController();
  Map<String, String?> userPhotos = {}; // Map to cache user profile photos

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    _messagesRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(appState.roomName!)
        .collection('messages');
  }

  void _sendMessage(String text) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.user != null && text.isNotEmpty) {
      _messagesRef.add({
        'text': text,
        'sender': appState.user!.displayName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': appState.user!.uid,
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userId = appState.userId ?? '';

    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop(); // Navigate back when pressed
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '${appState.roomName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
                      return Center(child: Text('An error occurred: ${snapshot.error}'));
                    }

                    List<DocumentSnapshot> docs = snapshot.data!.docs;
                    List<Map<String, dynamic>> messages = docs.reversed.map((doc) {
                      return doc.data() as Map<String, dynamic>;
                    }).toList();

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isUserMessage = message['userId'] == userId;
                        final timestamp = message['timestamp'] as int;
                        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                        final time = DateFormat('HH:mm').format(dateTime);
                        return _buildMessage(
                          message['text'],
                          message['sender'],
                          time,
                          isUserMessage,
                          message['userId'],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

 Widget _buildMessage(String text, String sender, String time, bool isUserMessage, String userId) {
  return Align(
    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isUserMessage ? Colors.green : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75, // Adjust maximum width as needed
      ),
      child: Column(
        crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUserMessage)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FutureBuilder<String?>(
                  future: Provider.of<AppState>(context, listen: false).getUserPhotoURL(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Icon(Icons.account_circle); // Placeholder if error occurs
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(snapshot.data!),
                      );
                    } else {
                      return Icon(Icons.account_circle); // Placeholder if no data
                    }
                  },
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        color: isUserMessage ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (isUserMessage)
            Text(
              text,
              style: TextStyle(
                color: isUserMessage ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              color: isUserMessage ? Colors.white70 : Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message ...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade300,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                _sendMessage(_textController.text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
