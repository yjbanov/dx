// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:dx/src/emitter.dart';
import 'package:dx/src/parser.dart';
import 'package:dx/src/scanner.dart';
import 'package:dx/src/token.dart';

/// Set this to `true` to make the test print more debugging to stdout.
const bool isDebug = false;

void main() {
  final languageDirectory = new Directory('test/language');
  if (!languageDirectory.existsSync()) {
    throw 'Directory not found: ${languageDirectory.path}';
  }

  for (File file in languageDirectory.listSync().where((f) => f.path.endsWith('.dx'))) {
    String expectedCode() {
      final pathWithoutExtension = path.withoutExtension(file.path);
      return new File('${pathWithoutExtension}.dart').readAsStringSync();
    }

    group('language test ${path.basename(file.path)}', () {
      String source;

      setUp(() {
        source = file.readAsStringSync();
      });

      test('scanner', () {
        if (isDebug) {
          print(source);
        }

        final scanner = new Scanner(Uri.parse(file.path), source);
        scanner.forEach((t) {
          expect(t is Token, true);
          if (isDebug) {
            print(t);
          }
        });
      });

      test('parser', () {
        final ast = parse(Uri.parse(file.path), source);
        expect(ast is DxAst, true);
        ast.toString();
        if (isDebug) {
          print(ast);
        }
      });

      test('emitter', () {
        final ast = parse(Uri.parse(file.path), source);
        final code = emit(ast);
        expect(code, expectedCode());
      });
    });
  }
}
