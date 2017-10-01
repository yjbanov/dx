// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:charcode/ascii.dart';
import 'package:string_scanner/string_scanner.dart';

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
    _scanSyntax();

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

  bool _scanSyntax() {
    if (_scanner.scan(_Patterns.syntax)) {
      _current = Syntax.lookupByName(_lastString);
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

abstract class Token {
  const Token();

  @override
  String toString() {
    throw '$runtimeType forgot to implement toString()';
  }
}

class Identifier extends Token {
  const Identifier(this.name);

  final String name;

  @override
  String toString() => '${runtimeType}(${name})';
}

class Keyword extends Token {
  static const $import = const Keyword('import');
  static const $widget = const Keyword('widget');
  static const $state = const Keyword('state');
  static const $build = const Keyword('build');

  static const List<Keyword> values = const <Keyword>[
    $import,
    $widget,
    $state,
    $build,
  ];

  static final List<String> names = new List.unmodifiable(values.map((k) => k.name));

  const Keyword(this.name);

  static final Map<String, Keyword> _nameToKeyword = new Map<String, Keyword>.fromIterable(
    Keyword.values,
    key: (k) => k.name,
  );

  static Keyword lookupByName(String name) {
    assert(name != null);
    return _nameToKeyword[name];
  }

  final String name;

  @override
  String toString() => '${runtimeType}("${name}")';
}

class Syntax extends Token {
  static const $openBrace = const Syntax('{', r'\{');
  static const $closeBrace = const Syntax('}', r'\}');
  static const $openParen = const Syntax('(', r'\(');
  static const $closeParen = const Syntax(')', r'\)');
  static const $lt = const Syntax('<', r'<');
  static const $gt = const Syntax('>', r'>');
  static const $dot = const Syntax('.', r'\.');
  static const $comma = const Syntax(',', r'\,');
  static const $equals = const Syntax('==', r'==');
  static const $assignment = const Syntax('=', r'=');
  static const $questionMark = const Syntax('?', r'\?');
  static const $exclamationMark = const Syntax('!', r'\!');
  static const $dollar = const Syntax('!', r'\$');
  static const $colon = const Syntax(':', r'\:');
  static const $slash = const Syntax('/', r'/');

  static const List<Syntax> values = const <Syntax>[
    $openBrace,
    $closeBrace,
    $openParen,
    $closeParen,
    $lt,
    $gt,
    $dot,
    $comma,
    $equals,
    $assignment,
    $questionMark,
    $exclamationMark,
    $dollar,
    $colon,
    $slash,
  ];

  static final Map<String, Syntax> _nameToSyntax = new Map<String, Syntax>.unmodifiable(
    new Map<String, Syntax>.fromIterable(
      values,
      key: (s) => s.token,
    )
  );

  static Syntax lookupByName(String name) => _nameToSyntax[name];

  const Syntax(this.token, this.pattern);

  final String token;
  final String pattern;

  @override
  String toString() => '${runtimeType}("${token}")';
}

class _Patterns {
  // TODO: this could use some smarts.
  static final $import = new RegExp(r'[\w_/\d\:]+');

  // TODO: check with the spec.
  static final identifier = new RegExp(
    r'[a-zA-Z_\$][\w\$]*'
  );

  static final syntax = new RegExp(
    Syntax.values.map((s) => s.pattern).join('|')
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
