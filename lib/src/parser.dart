// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'ast.dart';
export 'ast.dart';
import 'scanner.dart';
import 'token.dart';

/// Parses [dx] into AST.
DxAst parse(Uri sourceUrl, String dx) => new _Parser(new Scanner(sourceUrl, dx)).parse();

/// Parses a stream of [Token]s into [DxAst].
class _Parser {
  _Parser(Scanner scanner) : _tokens = scanner.iterator;

  final Iterator<Token> _tokens;

  DxAst parse() {
    final dxBuilder = new DxAstBuilder();

    _advance(allowEof: true);
    while (_match(const [Keyword.$import, Keyword.$widget], allowEof: true)) {
      if (_token == Keyword.$import) {
        _parseImportBlock(dxBuilder);
      } if (_token == Keyword.$widget) {
        _parseWidget(dxBuilder);
      }
    }

    if (_advance(allowEof: true)) {
      _unexpectedToken();
    }

    return dxBuilder.build();
  }

  void _parseImportBlock(DxAstBuilder parent) {
    assert(_token == Keyword.$import);

    _advance();
    _consumeToken(Punctuation.$openBrace);

    final builder = new ImportBlockAstBuilder();
    while (_token is Identifier || _match(const [Punctuation.$slash, Punctuation.$colon])) {
      _parseImport(builder);
      _consumeToken(Punctuation.$semicolon);
    }

    _consumeToken(Punctuation.$closeBrace, allowEof: true);
    parent.addChild(builder.build());
  }

  bool _parseImport(ImportBlockAstBuilder parent) {
    final builder = new ImportAstBuilder();

    bool expectIdentifier = true;
    while (_token != Punctuation.$semicolon) {
      final token = _token;

      if (expectIdentifier && token is! Identifier) {
        _unexpectedToken(expected: 'identifier');
      }

      if (!expectIdentifier && !(token == Punctuation.$slash || token == Punctuation.$colon)) {
        _unexpectedToken(expected: ': or /');
      }

      builder.append(token);
      _advance();
      expectIdentifier = !expectIdentifier;
    }

    parent.addChild(builder.build());
    return true;
  }

  void _parseWidget(DxAstBuilder parent) {
    assert(_token == Keyword.$widget);

    final widget = new WidgetAstBuilder();

    _advance();
    final widgetName = _expect<Identifier>((t) => t is Identifier);
    widget.className = widgetName.name;
    _advance();
    _consumeToken(Punctuation.$openBrace);

    while (_match(const <Token>[Keyword.$build, Keyword.$state])) {
      if (_token == Keyword.$build) {
        _parseBuild(widget);
      } else if (_token == Keyword.$state) {
        _parseState(widget);
      }
    }

    _consumeToken(Punctuation.$closeBrace, allowEof: true);
    parent.addChild(widget.build());
  }

  void _parseBuild(WidgetAstBuilder parent) {
    assert(_token == Keyword.$build);

    _advance();
    _consumeToken(Punctuation.$openBrace);
    _consumeToken(Punctuation.$closeBrace);
    parent.buildAst = new BuildAst();
  }

  void _parseState(WidgetAstBuilder parent) {
    assert(_token == Keyword.$state);

    _advance();
    _consumeToken(Punctuation.$openBrace);
    _consumeToken(Punctuation.$closeBrace);
    parent.stateAst = new StateAst();
  }

  void _consumeToken(Token token, {allowEof: false}) {
    _consume((t) => t == token, allowEof: allowEof);
  }

  void _consume(bool predicate(Token token), {allowEof: false}) {
    _expect(predicate);
    _advance(allowEof: allowEof);
  }

  T _expect<T extends Token>(bool predicate(Token token)) {
    if (!predicate(_token)) {
      _unexpectedToken();
    }
    return _token;
  }

  void _unexpectedToken({String expected}) {
    throw new _ParserException('Unexpected token ${_token}' + (expected != null ? '. Expected ${expected}.' : '.'));
  }

  bool _advance({bool allowEof: false}) {
    if (!_tokens.moveNext()) {
      if (allowEof) {
        return false;
      }
      throw new _ParserException('Unexpected end of source file.');
    }
    return true;
  }

  bool _match(List<Token> tokens, {bool allowEof: false}) {
    return tokens.any((token) => _token == token);
  }

  Token get _token => _tokens.current;
}

class _ParserException {
  _ParserException(this.message);

  final String message;

  @override
  String toString() => '${runtimeType}: ${message}';
}
