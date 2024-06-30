import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:voxbox/Screens/mybox_screen.dart';
import 'package:voxbox/Auth/app_state.dart';
import 'package:voxbox/Screens/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat Room App',
        home: AuthenticationWrapper(),
        routes: {
          '/room': (context) => MyBoxesScreen(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Check if the user is signed in
    if (appState.userId != null) {
      // If signed in, navigate to MyBoxesScreen
      return MyBoxesScreen();
    } else {
      // If not signed in, navigate to SignInScreen
      return SignInScreen();
    }
  }
}
