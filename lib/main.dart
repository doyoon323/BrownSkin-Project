import 'package:flutter/material.dart';
import 'package:brownskin_app/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //final token = "14259b24626fe1ada57e4aa18aa0de4247610f23";
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brownskin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const LoginPage(), //AdminHomePage(token: token),
    );
  }
}

//까지

