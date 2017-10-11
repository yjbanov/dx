// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:charcode/ascii.dart';
import 'package:string_scanner/string_scanner.dart';

import 'token.dart';

/// Extracts syntactic [Token]s from dx source code.
class Scanner extends IterableBase<Token> implements Iterable<Token> {
  Scanner(this.sourceUrl, this.dx);

  final Uri sourceUrl;
  final String dx;

  @override
  Iterator<Token> get iterator => new _ScannerIterator(sourceUrl, dx);
}

class _ScannerIterator implements Iterator<Token> {
  _ScannerIterator(Uri sourceUrl, String dx)
      : _scanner = new SpanScanner(dx, sourceUrl: sourceUrl);

  final SpanScanner _scanner;

  @override
  Token get current => _current;
  Token _current;

  @override
  bool moveNext() {
    _consumeWhitespace();

    if (_scanner.isDone) {
      return false;
    }

    if (!_scanNext()) {
      _scanner.expectDone();
    }

    return true;
  }

  bool _scanNext() =>
    _scanKeyword() ||
    _scanIdentifier() ||
    _scanPunctuation();

  bool _scanKeyword() {
    if (_scanner.scan(_Patterns.keyword)) {
      _current = Keyword.lookupByName(_scanner.lastMatch.group(1));
      return true;
    }
    return false;
  }

  bool _scanIdentifier() {
    if (_scanner.scan(_Patterns.identifier)) {
      _current = new Identifier(_lastString);
      return true;
    }
    return false;
  }

  bool _scanPunctuation() {
    if (_scanner.scan(_Patterns.punctuation)) {
      _current = Punctuation.lookupByName(_lastString);
      return true;
    }
    return false;
  }

  void _consumeWhitespace() {
    while (!_scanner.isDone && isWhitespace(_scanner.peekChar())) {
      _scanner.readChar();
    }
  }

  String get _lastString => _scanner.lastMatch[0];
}

class _Patterns {
  // TODO: this could use some smarts.
  static final $import = new RegExp(r'[\w_/\d\:]+');

  // TODO: check with the spec.
  static final identifier = new RegExp(
    r'[a-zA-Z_\$][\w\$]*'
  );

  static final punctuation = new RegExp(
    Punctuation.values.map((s) => s.pattern).join('|')
  );

  static final keyword = new RegExp(
    '(${Keyword.names.join('|')})\\s'
  );
}

// The following utilities were borrowed from:
// https://github.com/sass/dart-sass/blob/d4db75a8f98b1a6f78b93213eb0e5544efef7c19/lib/src/util/character.dart

/// Returns whether [character] is an ASCII whitespace character.
bool isWhitespace(int character) =>
    character == $space || character == $tab || isNewline(character);

/// Returns whether [character] is an ASCII newline.
bool isNewline(int character) =>
    character == $lf || character == $cr || character == $ff;
