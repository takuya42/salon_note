import 'package:flutter/material.dart';
import 'home/home_page.dart';

void main() {
  runApp(const SalonNoteApp());
}

class SalonNoteApp extends StatelessWidget {
  const SalonNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
