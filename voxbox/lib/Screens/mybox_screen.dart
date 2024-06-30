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
  String errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Stream<List<DocumentSnapshot>> _fetchRooms() {
    final appState = Provider.of<AppState>(context, listen: false);
    final String? userId = appState.userId;

    // Stream for rooms created by the user
    Stream<QuerySnapshot> createdRoomsStream = FirebaseFirestore.instance
        .collection('rooms')
        .where('owner', isEqualTo: userId)
        .snapshots();

    // Stream for rooms where the user is a participant
    Stream<QuerySnapshot> joinedRoomsStream = FirebaseFirestore.instance
        .collection('rooms')
        .where('participants', arrayContains: userId)
        .snapshots();

    return createdRoomsStream.asyncMap((createdRoomsSnapshot) async {
      Set<String> roomIds = {};
      List<DocumentSnapshot> uniqueRooms = [];

      for (var doc in createdRoomsSnapshot.docs) {
        if (roomIds.add(doc.id)) {
          uniqueRooms.add(doc);
        }
      }

      final joinedRoomsSnapshot = await joinedRoomsStream.first;
      for (var doc in joinedRoomsSnapshot.docs) {
        if (roomIds.add(doc.id)) {
          uniqueRooms.add(doc);
        }
      }

      return uniqueRooms;
    });
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
                    _nameController.clear();
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
    // Track error message state
    setState(() {
      errorMessage = '';
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _joinRoom(context, setState);
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
      },
    );
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

  void _joinRoom(BuildContext context, Function(void Function()) setState) {
    final appState = Provider.of<AppState>(context, listen: false);
    String roomId = _roomController.text.trim();

    final String? userId = appState.userId;

    if (roomId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get()
          .then((documentSnapshot) {
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
          setState(() {
            errorMessage =
                "Can't find a box with given id"; // Update error message state
          });
        }
      }).catchError((error) {
        print('Error joining room: $error');
        setState(() {
          errorMessage =
              'Error joining room: $error'; // Update error message state
        });
      });
    } else {
      setState(() {
        errorMessage = 'Room ID cannot be empty'; // Update error message state
      });
    }
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: _fetchRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Please create a new box or join an existing one',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                var room = snapshot.data![index];
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
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                  title: Text(room['name']),
                                  onTap: () {
                                    Provider.of<AppState>(context,
                                            listen: false)
                                        .setRoom(room.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MessagingScreen()),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(
                                height: 80), // Adjust as needed for input bar
                          ],
                        ),
                      );
                    }
                  },
                ),
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
