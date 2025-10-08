// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SnapshotOptions', () {
    test('Create SnapshotOptions with defaults', () {
      const options = SnapshotOptions();

      expect(options.showBuildings, true);
      expect(options.showPointsOfInterest, true);
      expect(options.showAnnotations, true);
      expect(options.showOverlays, true);
    });

    test('Create SnapshotOptions with custom values', () {
      const options = SnapshotOptions(
        showBuildings: false,
        showPointsOfInterest: false,
        showAnnotations: false,
        showOverlays: false,
      );

      expect(options.showBuildings, false);
      expect(options.showPointsOfInterest, false);
      expect(options.showAnnotations, false);
      expect(options.showOverlays, false);
    });

    test('SnapshotOptions equality', () {
      const options1 = SnapshotOptions(
        showBuildings: true,
        showPointsOfInterest: false,
        showAnnotations: true,
        showOverlays: false,
      );

      const options2 = SnapshotOptions(
        showBuildings: true,
        showPointsOfInterest: false,
        showAnnotations: true,
        showOverlays: false,
      );

      const options3 = SnapshotOptions(
        showBuildings: false, // Different
        showPointsOfInterest: false,
        showAnnotations: true,
        showOverlays: false,
      );

      expect(options1, equals(options2));
      expect(options1 == options3, false);
    });

    test('SnapshotOptions hashCode', () {
      const options1 = SnapshotOptions(
        showBuildings: true,
        showPointsOfInterest: false,
        showAnnotations: true,
        showOverlays: false,
      );

      const options2 = SnapshotOptions(
        showBuildings: true,
        showPointsOfInterest: false,
        showAnnotations: true,
        showOverlays: false,
      );

      expect(options1.hashCode, equals(options2.hashCode));
    });

    test('SnapshotOptions toString', () {
      const options = SnapshotOptions(
        showBuildings: true,
        showPointsOfInterest: false,
        showAnnotations: true,
        showOverlays: false,
      );

      final str = options.toString();
      expect(str, contains('SnapshotOptions'));
      expect(str, contains('showBuildings: true'));
      expect(str, contains('showPointsOfInterest: false'));
      expect(str, contains('showAnnotations: true'));
      expect(str, contains('showOverlays: false'));
    });

    test('SnapshotOptions with mixed values', () {
      const options = SnapshotOptions(
        showBuildings: false,
        showPointsOfInterest: true,
        showAnnotations: false,
        showOverlays: true,
      );

      expect(options.showBuildings, false);
      expect(options.showPointsOfInterest, true);
      expect(options.showAnnotations, false);
      expect(options.showOverlays, true);
    });

    test('SnapshotOptions fromMap', () {
      final options = SnapshotOptions.fromMap({
        'showBuildings': false,
        'showPointsOfInterest': true,
        'showAnnotations': false,
        'showOverlays': true,
      });

      expect(options?.showBuildings, false);
      expect(options?.showPointsOfInterest, true);
      expect(options?.showAnnotations, false);
      expect(options?.showOverlays, true);
    });

    test('SnapshotOptions fromMap with null returns null', () {
      final options = SnapshotOptions.fromMap(null);
      expect(options, isNull);
    });
  });
}
