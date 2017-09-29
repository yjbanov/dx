// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:charcode/ascii.dart';
import 'package:string_scanner/string_scanner.dart';

class Scanner extends IterableBase<Token> implements Iterable<Token> {
  Scanner(this.sourceUrl, this.dx);

  final Uri sourceUrl;
  final String dx;

  @override
  Iterator<Token> get iterator => new _ScannerIterator(sourceUrl, dx);
}

/// Produces a stream of [Token]s from dx source code.
class _ScannerIterator implements Iterator<Token> {
  _ScannerIterator(Uri sourceUrl, String dx)
      : _scanner = new SpanScanner(dx, sourceUrl: sourceUrl);

  final SpanScanner _scanner;
  ScannerContext _context = ScannerContext.$root;

  @override
  Token get current => _buffer[_index];
  int _index = 0;
  List<Token> _buffer = <Token>[];

  @override
  bool moveNext() {
    if (_index < _buffer.length - 1) {
      _index++;
      return true;
    }
    _buffer.clear();
    _index = 0;

    _consumeWhitespace();

    if (_scanner.isDone) {
      return false;
    }

    switch (_context) {
      case ScannerContext.$root:
        return _scanRoot();
      case ScannerContext.$import:
        return _scanImport();
      case ScannerContext.$widget:
        return _scanWidget();
      case ScannerContext.$state:
        return _scanState();
      case ScannerContext.$build:
        return _scanBuild();
    }

    _scanner.expectDone();
    return false;
  }

  bool _scanRoot() =>
    _scanImportStart() ||
    _scanWidgetStart();

  bool _scanImportStart() {
    if (!_scanKeywordBlockStart(Keyword.$import)) {
      return false;
    }
    _context = ScannerContext.$import;
    return true;
  }

  bool  _scanWidgetStart() {
    if (!_scanKeywordBlockStart(Keyword.$widget)) {
      return false;
    }
    _context = ScannerContext.$widget;
    return true;
  }

  bool  _scanStateStart() {
    if (!_scanKeywordBlockStart(Keyword.$state)) {
      return false;
    }
    _context = ScannerContext.$state;
    return true;
  }

  bool  _scanBuildStart() {
    if (!_scanKeywordBlockStart(Keyword.$build)) {
      return false;
    }
    _context = ScannerContext.$build;
    return true;
  }

  bool _scanKeywordBlockStart(Keyword keyword) {
    if (!_scanner.scan(keyword.keyword)) {
      return false;
    }
    _emit(keyword);
    _consumeWhitespace();
    _scanner.expectChar($open_brace);
    _emit(Syntax.$openBrace);
    return true;
  }

  bool _scanImport() {
    if (_scanner.scanChar($close_brace)) {
      _emit(Syntax.$closeBrace);
      _context = ScannerContext.$root;
    } else {
      _scanner.expect(_Patterns.$import);
      final lastSpan = _scanner.lastSpan;
      _emit(new LibraryImport(_scanner.substring(lastSpan.start.offset, lastSpan.end.offset)));
    }
    return true;
  }

  bool _scanWidget() {
    if (_scanner.scanChar($close_brace)) {
      _emit(Syntax.$closeBrace);
      _context = ScannerContext.$root;
      return true;
    } else if (_scanStateStart() || _scanBuildStart()) {
      return true;
    }
    throw _scanner.error('Widget block ended unexpectedly.');
  }

  bool _scanState() {
    // TODO: implement
    _scanner.expectChar($close_brace);
    _emit(Syntax.$closeBrace);
    _context = ScannerContext.$widget;
    return true;
  }

  bool _scanBuild() {
    // TODO: implement
    _scanner.expectChar($close_brace);
    _emit(Syntax.$closeBrace);
    _context = ScannerContext.$widget;
    return true;
  }

  void _emit(Token token) {
    _buffer.add(token);
  }

  void _consumeWhitespace() {
    while (!_scanner.isDone && isWhitespace(_scanner.peekChar())) {
      _scanner.readChar();
    }
  }
}

enum ScannerContext {
  $root,
  $import,
  $widget,
  $state,
  $build,
}

class _Keyword {
  static const $import = 'import';
  static const $widget = 'widget';
  static const $state = 'state';
  static const $build = 'build';
}

abstract class Token {
  const Token();

  @override
  String toString() {
    throw '$runtimeType forgot to implement toString()';
  }
}

class LibraryImport extends Token {
  const LibraryImport(this.path);

  final String path;

  @override
  String toString() => '${runtimeType}';
}

class Keyword extends Token {
  static const $import = const Keyword(_Keyword.$import);
  static const $widget = const Keyword(_Keyword.$widget);
  static const $state = const Keyword(_Keyword.$state);
  static const $build = const Keyword(_Keyword.$build);

  const Keyword(this.keyword);

  final String keyword;

  @override
  String toString() => '${runtimeType}("${keyword}")';
}

class Syntax extends Token {
  static const $openBrace = const Syntax('{');
  static const $closeBrace = const Syntax('}');
  static const $openParen = const Syntax('(');
  static const $closeParen = const Syntax(')');
  static const $lt = const Syntax('<');
  static const $gt = const Syntax('>');
  static const $dot = const Syntax('.');
  static const $comma = const Syntax(',');
  static const $assignment = const Syntax('=');
  static const $equals = const Syntax('==');
  static const $questionMark = const Syntax('?');
  static const $exclamationMark = const Syntax('!');

  const Syntax(this.token);

  final String token;

  @override
  String toString() => '${runtimeType}("${token}")';
}

class _Patterns {
  // TODO: this could use some smarts.
  static final $import = new RegExp(r'[\w_/\d\:]+');
}

// The following utilities were borrowed from:
// https://github.com/sass/dart-sass/blob/d4db75a8f98b1a6f78b93213eb0e5544efef7c19/lib/src/util/character.dart

/// Returns whether [character] is an ASCII whitespace character.
bool isWhitespace(int character) =>
    character == $space || character == $tab || isNewline(character);

/// Returns whether [character] is an ASCII newline.
bool isNewline(int character) =>
    character == $lf || character == $cr || character == $ff;
