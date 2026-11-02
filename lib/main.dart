import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: RepTrailApp()));
}

class RepTrailApp extends StatelessWidget {
  const RepTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RepTrail',
      home: Scaffold(body: Center(child: Text('Firebase connected'))),
    );
  }
}