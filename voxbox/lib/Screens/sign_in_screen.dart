import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voxbox/Auth/app_state.dart';
import 'package:voxbox/constants.dart';

class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Image.asset('assets/images/Vox Box.png'),
            Spacer(),
            Container(
              height: 316,
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 48),
                  Text(
                    'Login to continue',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await appState.signInWithGoogle();
                      if (appState.user != null) {
                        Navigator.pushReplacementNamed(context, '/room');
                      }
                    },
                    icon: Image.asset(
                      'assets/icons/google_logo.png', 
                      height: 30,
                      width: 30,
                    ), // Make sure to add Google logo in assets
                    label: Text('Continue with Google'),
                    style: ElevatedButton.styleFrom(
                      
                      minimumSize: Size(double.infinity, 50),
                      textStyle: TextStyle(fontSize: 20, color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
