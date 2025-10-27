import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeMode', () {
    test('ThemeMode enum has correct values', () {
      expect(ThemeMode.system.index, 0);
      expect(ThemeMode.light.index, 1);
      expect(ThemeMode.dark.index, 2);
    });

    test('ThemeMode enum has correct string representations', () {
      expect(ThemeMode.system.toString(), 'ThemeMode.system');
      expect(ThemeMode.light.toString(), 'ThemeMode.light');
      expect(ThemeMode.dark.toString(), 'ThemeMode.dark');
    });
  });

  group('AppleMap with theme', () {
    test('AppleMap accepts ThemeMode parameter', () {
      const cameraPosition = CameraPosition(
        target: LatLng(0.0, 0.0),
        zoom: 12.0,
      );

      final appleMap = AppleMap(
        initialCameraPosition: cameraPosition,
        mapTheme: ThemeMode.dark,
      );

      expect(appleMap.mapTheme, ThemeMode.dark);
    });

    test('AppleMap defaults to system theme', () {
      const cameraPosition = CameraPosition(
        target: LatLng(0.0, 0.0),
        zoom: 12.0,
      );

      final appleMap = AppleMap(
        initialCameraPosition: cameraPosition,
      );

      expect(appleMap.mapTheme, ThemeMode.system);
    });
  });
}
