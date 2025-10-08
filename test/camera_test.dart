// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraPosition', () {
    test('Create CameraPosition with required target', () {
      const position = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
      );

      expect(position.target, const LatLng(37.4231613, -122.087159));
      expect(position.heading, 0.0);
      expect(position.pitch, 0.0);
      expect(position.zoom, 0);
    });

    test('Create CameraPosition with all parameters', () {
      const position = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
        heading: 90.0,
        pitch: 30.0,
        zoom: 15.0,
      );

      expect(position.target, const LatLng(37.4231613, -122.087159));
      expect(position.heading, 90.0);
      expect(position.pitch, 30.0);
      expect(position.zoom, 15.0);
    });

    test('CameraPosition equality', () {
      const position1 = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
        heading: 90.0,
        pitch: 30.0,
        zoom: 15.0,
      );

      const position2 = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
        heading: 90.0,
        pitch: 30.0,
        zoom: 15.0,
      );

      const position3 = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
        heading: 80.0, // Different
        pitch: 30.0,
        zoom: 15.0,
      );

      expect(position1, equals(position2));
      expect(position1 == position3, false);
      expect(position1.hashCode, equals(position2.hashCode));
    });

    test('CameraPosition toString', () {
      const position = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
        heading: 90.0,
        pitch: 30.0,
        zoom: 15.0,
      );

      expect(
        position.toString(),
        contains('CameraPosition'),
      );
      expect(position.toString(), contains('90.0'));
      expect(position.toString(), contains('30.0'));
      expect(position.toString(), contains('15.0'));
    });

    test('CameraPosition fromMap', () {
      final position = CameraPosition.fromMap({
        'target': [37.4231613, -122.087159],
        'heading': 90.0,
        'pitch': 30.0,
        'zoom': 15.0,
      });

      expect(position?.target, const LatLng(37.4231613, -122.087159));
      expect(position?.heading, 90.0);
      expect(position?.pitch, 30.0);
      expect(position?.zoom, 15.0);
    });

    test('CameraPosition fromMap with null returns null', () {
      final position = CameraPosition.fromMap(null);
      expect(position, isNull);
    });
  });

  group('CameraUpdate', () {
    test('newCameraPosition', () {
      const position = CameraPosition(
        target: LatLng(37.4231613, -122.087159),
        heading: 90.0,
        pitch: 30.0,
        zoom: 15.0,
      );

      final update = CameraUpdate.newCameraPosition(position);
      expect(update, isNotNull);
    });

    test('newLatLng', () {
      const latLng = LatLng(37.4231613, -122.087159);
      final update = CameraUpdate.newLatLng(latLng);
      expect(update, isNotNull);
    });

    test('newLatLngZoom', () {
      const latLng = LatLng(37.4231613, -122.087159);
      final update = CameraUpdate.newLatLngZoom(latLng, 15.0);
      expect(update, isNotNull);
    });

    test('newLatLngBounds', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.0, -122.5),
        northeast: const LatLng(38.0, -121.5),
      );
      final update = CameraUpdate.newLatLngBounds(bounds, 50.0);
      expect(update, isNotNull);
    });

    test('zoomBy', () {
      final update = CameraUpdate.zoomBy(1.5);
      expect(update, isNotNull);
    });

    test('zoomBy with focus', () {
      const focus = Offset(100, 100);
      final update = CameraUpdate.zoomBy(1.5, focus);
      expect(update, isNotNull);
    });

    test('zoomIn', () {
      final update = CameraUpdate.zoomIn();
      expect(update, isNotNull);
    });

    test('zoomOut', () {
      final update = CameraUpdate.zoomOut();
      expect(update, isNotNull);
    });

    test('zoomTo', () {
      final update = CameraUpdate.zoomTo(15.0);
      expect(update, isNotNull);
    });
  });
}
