import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shopsnports/firebase_options_staging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/providers/firestore_provider.dart';
import 'package:shopsnports/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(overrides: [
    firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
  ], child: const app.MyApp()));
}
