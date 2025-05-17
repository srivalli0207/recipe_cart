import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/screens/auth/auth_screen.dart';
import 'package:recipe_cart/screens/home/main_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    // Return either Home or Authenticate widget
    if (user == null) {
      return const AuthScreen();
    } else {
      return const MainScreen();
    }
  }
}