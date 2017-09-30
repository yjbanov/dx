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
    _consume(Punctuation.$openBrace);

    final builder = new ImportBlockAstBuilder();
    while (_token is Identifier || _match(const [Punctuation.$slash, Punctuation.$colon])) {
      _parseImport(builder);
      _consume(Punctuation.$semicolon);
    }

    _consume(Punctuation.$closeBrace, allowEof: true);
    parent.addChild(builder.build());
  }

  bool _parseImport(ImportBlockAstBuilder parent) {
    final builder = new ImportAstBuilder();

    while (_token != Punctuation.$semicolon) {
      final token = _token;  // Need var for type inference.
      if (token is Identifier) {
        builder.append(token.name);
      } else if (token == Punctuation.$slash || token == Punctuation.$colon) {
        builder.append((token as Punctuation).token);
      } else {
        _unexpectedToken();
      }
      _advance();
    }

    parent.addChild(builder.build());
    return true;
  }

  void _parseWidget(DxAstBuilder parent) {
    assert(_token == Keyword.$widget);

    _advance();
    _consume(Punctuation.$openBrace);

    final widget = new WidgetAstBuilder();
    while (_match(const <Token>[Keyword.$build, Keyword.$state])) {
      if (_token == Keyword.$build) {
        _parseBuild(widget);
      } else if (_token == Keyword.$state) {
        _parseState(widget);
      }
    }

    _consume(Punctuation.$closeBrace, allowEof: true);
    parent.addChild(widget.build());
  }

  void _parseBuild(WidgetAstBuilder parent) {
    assert(_token == Keyword.$build);

    _advance();
    _consume(Punctuation.$openBrace);
    _consume(Punctuation.$closeBrace);
    parent.buildAst = new BuildAst();
  }

  void _parseState(WidgetAstBuilder parent) {
    assert(_token == Keyword.$state);

    _advance();
    _consume(Punctuation.$openBrace);
    _consume(Punctuation.$closeBrace);
    parent.stateAst = new StateAst();
  }

  void _consume(Token token, {allowEof: false}) {
    _expect(token);
    _advance(allowEof: allowEof);
  }

  void _expect(Token token) {
    if (_token != token) {
      _unexpectedToken();
    }
  }

  void _unexpectedToken() {
    throw new _ParserException('Unexpected token ${_token}');
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
