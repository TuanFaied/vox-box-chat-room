import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  String? _roomName;
  String? _displayName;

  AppState() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _displayName = user?.displayName; 
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get userId => _user?.uid;
  String? get roomName => _roomName;
  String? get displayName => _displayName;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      _displayName = _user?.displayName; 
      print(_displayName);
      notifyListeners();
    } catch (error) {
      print('Error during Google sign-in: $error');
      // Handle the error (e.g., show a message to the user)
    }
  }

  void setRoom(String room, ) {
    _roomName = room;
    // _displayName = name;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _user = null;
    _roomName = null;
    _displayName = null; // Reset the display name
    notifyListeners();
  }
}
