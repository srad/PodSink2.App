import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/presentation/screens/playing_history.dart';
import 'package:podsink2/presentation/shared_widgets/animated_logo.dart';

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
              gradient: LinearGradient(
                // Using a similar gradient for drawer header
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber.shade500, Colors.amber.shade900], //
              ),
            ),
            child: Row(children: [
            Text('Podsink', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
              Spacer(),
              AnimatedLogoWidget(frameAssetPaths: ['assets/icons/animation_1.png', 'assets/icons/animation_2.png', 'assets/icons/animation_3.png', 'assets/icons/animation_4.png'], width: 100, frameDuration: Duration(milliseconds: 700)),//
            ]),
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
