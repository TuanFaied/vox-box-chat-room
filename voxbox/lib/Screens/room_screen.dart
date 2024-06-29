// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:voxbox/Auth/app_state.dart';
// import 'package:firebase_database/firebase_database.dart'; 

// import 'messaging_screen.dart';

// class RoomScreen extends StatelessWidget {
//   final TextEditingController _roomController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<AppState>(context);

//     void _createRoom() {
//       String roomName = _roomController.text.trim();
//       String displayName = _nameController.text.trim();

//       if (roomName.isNotEmpty && displayName.isNotEmpty) {
//         FirebaseDatabase.instance.reference().child('rooms').child(roomName).set({
//           'name': displayName,
//           'timestamp': DateTime.now().millisecondsSinceEpoch,
//         }).then((_) {
//           appState.setRoom(roomName, displayName);
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => MessagingScreen()),
//           );
//         });
//       }
//     }

//     void _joinRoom() {
//       String roomId = _roomController.text.trim();
//       String displayName = _nameController.text.trim();
    
//       if (roomId.isNotEmpty && displayName.isNotEmpty) {
//         FirebaseDatabase.instance.reference().child('rooms').child(roomId).once().then((DatabaseEvent event) {
//           if (event.snapshot.exists) {
//             appState.setRoom(roomId, displayName);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => MessagingScreen()),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Room does not exist')));
//           }
//         });
//       }
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text('Room')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _roomController,
//               decoration: InputDecoration(labelText: 'Room Name/ID'),
//             ),
//             TextField(
//               controller: _nameController,
//               decoration: InputDecoration(labelText: 'Display Name'),
//             ),
//             SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(onPressed: _createRoom, child: Text('Create Room')),
//                 ElevatedButton(onPressed: _joinRoom, child: Text('Join Room')),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
