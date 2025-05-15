import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/presentation/screens/home.dart';

class PodSink2 extends StatelessWidget {
  const PodSink2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Podcast App',
      theme: ThemeData(
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: Colors.transparent, // For gradient to show through
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.white, // Default text color for gradient background
            displayColor: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            foregroundColor: Colors.white, // For title and icons
            elevation: 0, // No shadow
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          listTileTheme: ListTileThemeData(
            iconColor: Colors.white70,
            textColor: Colors.white,
            selectedTileColor: Colors.amber.shade300.withValues(alpha: 0.3),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            hintStyle: TextStyle(color: Colors.white70),
            prefixIconColor: Colors.white70,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            border: OutlineInputBorder( // Default border
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          cardTheme: CardTheme(
            color: Colors.white.withValues(alpha: 0.15),
            elevation: 0, // Remove shadow if using transparent background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              // side: BorderSide(color: Colors.white.withValues(alpha: 0.2)), // Optional border
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white70),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white)
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white//
              )
          )
      ),
      home: const HomeScreen(),//
    );
  }
}