import 'package:flutter/material.dart';
import 'package:shopsnports/screens/splash_screen.dart';
import 'package:shopsnports/styles/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopsNports',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const SplashScreen(),
    );
  }
}
