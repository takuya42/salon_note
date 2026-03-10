import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'role_select/role_select_page.dart';

void main() {
  runApp(const SalonNoteApp());
}

class SalonNoteApp extends StatelessWidget {
  const SalonNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SalonNote',

      theme: ThemeData.light(),

      locale: const Locale('ja'),

      supportedLocales: const [
        Locale('ja'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const RoleSelectPage(),
    );
  }
}