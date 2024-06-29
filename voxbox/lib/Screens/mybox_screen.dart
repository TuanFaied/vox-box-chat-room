import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voxbox/Auth/app_state.dart';
import 'package:voxbox/constants.dart';
import 'package:voxbox/screens/messaging_screen.dart';

class MyBoxesScreen extends StatefulWidget {
  @override
  _MyBoxesScreenState createState() => _MyBoxesScreenState();
}

class _MyBoxesScreenState extends State<MyBoxesScreen> {
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<DocumentSnapshot> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

 void _fetchRooms() async {
  final appState = Provider.of<AppState>(context, listen: false);
  final String? userId = appState.userId;

  // Fetch rooms created by the user
  QuerySnapshot createdRoomsSnapshot = await FirebaseFirestore.instance
      .collection('rooms')
      .where('owner', isEqualTo: userId)
      .get();

  // Fetch rooms where the user is a participant
  QuerySnapshot joinedRoomsSnapshot = await FirebaseFirestore.instance
      .collection('rooms')
      .where('participants', arrayContains: userId)
      .get();

  // Use a Set to track unique room IDs
  Set<String> roomIds = {};
  List<QueryDocumentSnapshot> uniqueRooms = [];

  for (var doc in createdRoomsSnapshot.docs) {
    if (roomIds.add(doc.id)) {
      uniqueRooms.add(doc);
    }
  }

  for (var doc in joinedRoomsSnapshot.docs) {
    if (roomIds.add(doc.id)) {
      uniqueRooms.add(doc);
    }
  }

  setState(() {
    _rooms = uniqueRooms;
  });
}


  void _createRoom(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    String roomName = _nameController.text.trim();
    
    final String? userId = appState.userId;

    if (roomName.isNotEmpty) {
      FirebaseFirestore.instance.collection('rooms').doc(roomName).set({
        'name': roomName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'owner': userId,
        'participants': [userId],
      }).then((_) {
        appState.setRoom(roomName);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MessagingScreen()),
        );
      }).catchError((error) {
        print('Error creating room: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating room: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room name cannot be empty')),
      );
    }
  }

  void _joinRoom(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    String roomId = _roomController.text.trim();
    
    final String? userId = appState.userId;

    if (roomId.isNotEmpty ) {
      FirebaseFirestore.instance.collection('rooms').doc(roomId).get().then((documentSnapshot) {
        if (documentSnapshot.exists) {
          FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
            'participants': FieldValue.arrayUnion([userId]),
          }).then((_) {
            appState.setRoom(roomId);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MessagingScreen()),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room does not exist')),
          );
        }
      }).catchError((error) {
        print('Error joining room: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining room: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room ID cannot be empty')),
      );
    }
  }

  void _showCreateBoxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Create New Box',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Box Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _createRoom(context);
                  },
                  child: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinBoxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join Box'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  hintText: 'Box ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _joinRoom(context);
                  },
                  child: const Text('Join'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'My Boxes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 690,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: _rooms.isEmpty
                  ? const Center(
                      child: Text(
                        'Please create a new box or join to existing one',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        var room = _rooms[index];
                        String roomName = room['name'];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              roomName.isNotEmpty ? roomName[0] : '',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          title: Text(room['name']),
                          
                          onTap: () {
                            Provider.of<AppState>(context, listen: false).setRoom(room.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MessagingScreen()),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final RenderBox overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox;
              final RelativeRect position = RelativeRect.fromRect(
                Rect.fromPoints(
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                  button.localToGlobal(button.size.bottomRight(Offset.zero),
                      ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );

              showMenu(
                context: context,
                position: position.shift(const Offset(-60, -110)),
                items: [
                  const PopupMenuItem<int>(
                    value: 1,
                    child: Text("Create a new box"),
                  ),
                  const PopupMenuItem<int>(
                    value: 2,
                    child: Text("Join a box"),
                  ),
                ],
              ).then((value) {
                if (value != null) {
                  if (value == 1) {
                    _showCreateBoxDialog(context);
                  } else {
                    _showJoinBoxDialog(context);
                  }
                }
              });
            },
            backgroundColor: kPrimaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }
}
