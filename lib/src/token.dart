// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class Token {
  const Token();

  @override
  String toString() {
    throw '$runtimeType forgot to implement toString()';
  }

  @override
  int get hashCode {
    throw '$runtimeType forgot to implement hashCode';
  }

  @override
  bool operator ==(Object other) {
    throw '$runtimeType forgot to implement operator==';
  }
}

class Identifier extends Token {
  const Identifier(this.name);

  final String name;

  @override
  String toString() => '${runtimeType}(${name})';

  @override
  int get hashCode => runtimeType.hashCode ^ name.hashCode;

  @override
  bool operator ==(Object other) => other is Identifier && other.name == name;
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

  @override
  int get hashCode => runtimeType.hashCode ^ name.hashCode;

  @override
  bool operator ==(Object other) => other is Keyword && other.name == name;
}

class Punctuation extends Token {
  static const $openBrace = const Punctuation('{', r'\{');
  static const $closeBrace = const Punctuation('}', r'\}');
  static const $openParen = const Punctuation('(', r'\(');
  static const $closeParen = const Punctuation(')', r'\)');
  static const $lt = const Punctuation('<', r'<');
  static const $gt = const Punctuation('>', r'>');
  static const $dot = const Punctuation('.', r'\.');
  static const $comma = const Punctuation(',', r'\,');
  static const $equals = const Punctuation('==', r'==');
  static const $assignment = const Punctuation('=', r'=');
  static const $questionMark = const Punctuation('?', r'\?');
  static const $exclamationMark = const Punctuation('!', r'\!');
  static const $dollar = const Punctuation('!', r'\$');
  static const $colon = const Punctuation(':', r'\:');
  static const $slash = const Punctuation('/', r'/');
  static const $semicolon = const Punctuation(';', r';');

  static const List<Punctuation> values = const <Punctuation>[
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
    $semicolon,
  ];

  static final Map<String, Punctuation> _nameToPunctuation = new Map<String, Punctuation>.unmodifiable(
    new Map<String, Punctuation>.fromIterable(
      values,
      key: (s) => s.token,
    )
  );

  static Punctuation lookupByName(String name) => _nameToPunctuation[name];

  const Punctuation(this.token, this.pattern);

  final String token;
  final String pattern;

  @override
  String toString() => '${runtimeType}("${token}")';

  @override
  int get hashCode => runtimeType.hashCode ^ token.hashCode;

  @override
  bool operator ==(Object other) => other is Punctuation && other.token == token;
}
