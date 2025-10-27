import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _currentTheme = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Apple Maps with Theme Support'),
          actions: [
            PopupMenuButton<ThemeMode>(
              onSelected: (ThemeMode theme) {
                setState(() {
                  _currentTheme = theme;
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<ThemeMode>>[
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Text('System Theme'),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Text('Light Theme'),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Text('Dark Theme'),
                ),
              ],
            ),
          ],
        ),
        body: AppleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(37.7749, -122.4194), // San Francisco
            zoom: 12,
          ),
          mapTheme: _currentTheme,
          onMapCreated: (AppleMapController controller) {
            print('Map created with theme: $_currentTheme');
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // You can also change the theme programmatically
            final themes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
            final currentIndex = themes.indexOf(_currentTheme);
            final nextIndex = (currentIndex + 1) % themes.length;
            setState(() {
              _currentTheme = themes[nextIndex];
            });
          },
          child: const Icon(Icons.brightness_6),
        ),
      ),
    );
  }
}
