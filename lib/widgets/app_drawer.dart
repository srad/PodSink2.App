import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/screens/playing_history.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black45.withValues(alpha: 0.95),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
                gradient: LinearGradient( // Using a similar gradient for drawer header
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.amber.shade900, Colors.amber.shade700],
                )
            ),
            child: const Text(
              'Podsink2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white70),
            title: const Text('Playing History', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayingHistoryScreen()));
            },
          ),
          // Add other drawer items here if needed
        ],
      ),
    );
  }
}