// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LatLng', () {
    test('Create LatLng', () {
      const latLng = LatLng(37.4231613, -122.087159);

      expect(latLng.latitude, 37.4231613);
      expect(latLng.longitude, -122.087159);
    });

    test('LatLng equality', () {
      const latLng1 = LatLng(37.4231613, -122.087159);
      const latLng2 = LatLng(37.4231613, -122.087159);
      const latLng3 = LatLng(37.4231614, -122.087159); // Different

      expect(latLng1, equals(latLng2));
      expect(latLng1 == latLng3, false);
      expect(latLng1.hashCode, equals(latLng2.hashCode));
    });

    test('LatLng toString', () {
      const latLng = LatLng(37.4231613, -122.087159);

      expect(latLng.toString(), contains('LatLng'));
      expect(latLng.toString(), contains('37.4231613'));
      expect(latLng.toString(), contains('-122.087159'));
    });

    test('LatLng with zero coordinates', () {
      const latLng = LatLng(0.0, 0.0);

      expect(latLng.latitude, 0.0);
      expect(latLng.longitude, 0.0);
    });

    test('LatLng with extreme coordinates', () {
      const northPole = LatLng(90.0, 0.0);
      const southPole = LatLng(-90.0, 0.0);
      const dateLine = LatLng(0.0, 180.0);

      expect(northPole.latitude, 90.0);
      expect(southPole.latitude, -90.0);
      // Longitude can normalize to -180 to 180 range
      expect(dateLine.longitude.abs(), 180.0);
    });
  });

  group('LatLngBounds', () {
    test('Create LatLngBounds', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(38.0, -121.5),
      );

      expect(bounds.southwest, const LatLng(37.0, -122.5));
      expect(bounds.northeast, const LatLng(38.0, -121.5));
    });

    test('LatLngBounds contains', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(38.0, -121.5),
      );

      // Inside bounds
      expect(bounds.contains(const LatLng(37.5, -122.0)), true);

      // Outside bounds
      expect(bounds.contains(const LatLng(36.5, -122.0)), false);
      expect(bounds.contains(const LatLng(38.5, -122.0)), false);
      expect(bounds.contains(const LatLng(37.5, -123.0)), false);
      expect(bounds.contains(const LatLng(37.5, -121.0)), false);

      // On boundaries
      expect(bounds.contains(const LatLng(37.0, -122.5)), true);
      expect(bounds.contains(const LatLng(38.0, -121.5)), true);
    });

    test('LatLngBounds equality', () {
      final bounds1 = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(38.0, -121.5),
      );

      final bounds2 = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(38.0, -121.5),
      );

      final bounds3 = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(39.0, -121.5), // Different
      );

      expect(bounds1, equals(bounds2));
      expect(bounds1 == bounds3, false);
      expect(bounds1.hashCode, equals(bounds2.hashCode));
    });

    test('LatLngBounds toString', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(38.0, -121.5),
      );

      expect(bounds.toString(), contains('LatLngBounds'));
      expect(bounds.toString(), contains('37.0'));
      expect(bounds.toString(), contains('38.0'));
    });

    test('LatLngBounds from JSON', () {
      final bounds = LatLngBounds.fromList([
        [37.0, -122.5],
        [38.0, -121.5],
      ]);

      expect(bounds?.southwest, const LatLng(37.0, -122.5));
      expect(bounds?.northeast, const LatLng(38.0, -121.5));
    });

    test('LatLngBounds from JSON with null returns null', () {
      final bounds = LatLngBounds.fromList(null);
      expect(bounds, isNull);
    });
  });
}
