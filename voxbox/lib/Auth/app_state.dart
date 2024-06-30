import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  String? _roomName;
  String? _displayName;
  late final StreamSubscription<User?> _authStateSubscription;

  AppState() {
    // Listen to authentication state changes and update user data accordingly
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
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
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      _displayName = _user?.displayName;
      notifyListeners();
    } catch (error) {
      print('Error during Google sign-in: $error');
      // Handle the error (e.g., show a message to the user)
    }
  }

  Future<String?> getUserPhotoURL(String userId) async {
  try {
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final data = snapshot.data() as Map<String, dynamic>?; // Explicit cast
    return data?['photoURL'] ?? ''; // Accessing 'photoURL' safely
  } catch (error) {
    print('Error fetching user photo URL: $error');
    return null;
  }
}


  void setRoom(String room) {
    _roomName = room;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      _roomName = null;
      _displayName = null;
      notifyListeners();
    } catch (error) {
      print('Error during sign-out: $error');
      // Handle the error (e.g., show a message to the user)
    }
  }

  @override
  void dispose() {
    // Dispose the subscription to avoid memory leaks
    _authStateSubscription.cancel();
    super.dispose();
  }
}
