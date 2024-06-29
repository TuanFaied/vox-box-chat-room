import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:voxbox/Screens/mybox_screen.dart';
import 'Auth/app_state.dart';
import 'Screens/sign_in_screen.dart';
import 'Screens/room_screen.dart';

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
        initialRoute: '/',
        routes: {
          '/': (context) => SignInScreen(),
          '/room': (context) => MyBoxesScreen(),
        },
      ),
    );
  }
}
