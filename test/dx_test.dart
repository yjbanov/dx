// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:dx/src/scanner.dart';

void main() {
  final languageDirectory = new Directory('test/language');
  if (!languageDirectory.existsSync()) {
    throw 'Directory not found: ${languageDirectory.path}';
  }

  group('language test', () {
    for (File file in languageDirectory.listSync()) {
      test('language test ${path.basename(file.path)}', () {
        final scanner = new Scanner(Uri.parse(file.path), file.readAsStringSync());
        scanner.forEach(print);
      });
    }
  });
}
