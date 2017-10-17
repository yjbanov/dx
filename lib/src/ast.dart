// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'token.dart';

/// The visitor interface for the visitor pattern implemented by the [Ast]
/// tree.
abstract class AstVisitor {
  void visitDxAst(DxAst node);
  void visitImportBlockAst(ImportBlockAst node);
  void visitImportAst(ImportAst node);
  void visitWidgetAst(WidgetAst node);
  void visitStateAst(StateAst node);
  void visitBuildAst(BuildAst node);
}

/// Common super-class of all AST node classes.
///
/// An AST node is a deeply immutable data structure.
@immutable
abstract class Ast {
  /// Calls a method of [AstVisitor] appropriate for the concrete
  /// implementation of the [Ast] node.
  void accept(AstVisitor visitor);

  @override
  String toString([int indent = 0]) {
    throw '$runtimeType forgot to implement toString([int indent = 0])';
  }
}

/// Builds an AST node.
///
/// Builders are mutable.
abstract class AstBuilder<T extends Ast> {
  T build();
}

abstract class AstWithChildren<C extends Ast> extends Ast {
  AstWithChildren({
    @required this.children,
  }) {
    assert(children != null);
  }

  final List<C> children;

  String _printChildren(int indent) {
    return children.map((c) => '${c.toString(indent)}\n').join('');
  }
}

abstract class AstWithChildrenBuilderMixin<C extends Ast> {
  final List<C> children = <C>[];

  void addChild(C node) {
    children.add(node);
  }
}

/// Represents the root of a .dx file.
class DxAst extends AstWithChildren<Ast> {
  DxAst({List<Ast> children}) : super(children: children);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitDxAst(this);
  }

  @override
  String toString([int indent = 0]) {
    final result = new StringBuffer('$runtimeType(');
    if (children.isNotEmpty) {
      result
        ..writeln()
        ..write(_printChildren(indent + 1));
    }
    result.write(')');
    return _indent(result.toString(), by: indent);
  }
}

class DxAstBuilder extends AstBuilder<DxAst>
    with AstWithChildrenBuilderMixin<Ast> {
  @override
  DxAst build() {
    return new DxAst(
      children: new List.unmodifiable(children),
    );
  }
}

class ImportAst extends Ast {
  ImportAst({
    @required this.pathTokens,
  });

  final List<Token> pathTokens;

  @override
  void accept(AstVisitor visitor) {
    visitor.visitImportAst(this);
  }

  @override
  String toString([int indent = 0]) {
    return _indent('$runtimeType(${pathTokens.join()})', by: indent);
  }  
}

class ImportAstBuilder extends AstBuilder<ImportAst> {
  final List<Token> _pathTokens = <Token>[];

  void append(Token part) {
    assert(part is Identifier || part == Punctuation.$colon || part == Punctuation.$slash);
    _pathTokens.add(part);
  }

  ImportAst build() => new ImportAst(pathTokens: new List<Token>.unmodifiable(_pathTokens));
}

class ImportBlockAst extends AstWithChildren<ImportAst> {
  ImportBlockAst({List<ImportAst> children}) : super(children: children);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitImportBlockAst(this);
  }

  @override
  String toString([int indent = 0]) {
    final result = new StringBuffer('$runtimeType(');
    if (children.isNotEmpty) {
      result
        ..writeln()
        ..write(_printChildren(1));
    }
    result.write(')');
    return _indent(result.toString(), by: indent);
  }
}

class ImportBlockAstBuilder extends AstBuilder<ImportBlockAst>
    with AstWithChildrenBuilderMixin<ImportAst> {
  @override
  ImportBlockAst build() {
    return new ImportBlockAst(
      children: new List.unmodifiable(children),
    );
  }
}

/// A widget class.
class WidgetAst extends Ast {
  WidgetAst({
    @required this.className,
    this.stateAst,
    @required this.buildAst,
  });

  final String className;
  final StateAst stateAst;
  final BuildAst buildAst;

  @override
  void accept(AstVisitor visitor) {
    visitor.visitWidgetAst(this);
  }

  @override
  String toString([int indent = 0]) {
    final buf = new StringBuffer('$runtimeType(\n');
    buf.writeln('  name: ${className}');
    if (stateAst != null) {
      buf.writeln('  state:\n${stateAst.toString(indent + 1)}');
    }
    buf.writeln('  build:\n${buildAst.toString(indent + 1)}');
    buf.write(')');
    return _indent(buf.toString(), by: indent);
  }  
}

class WidgetAstBuilder extends AstBuilder<WidgetAst> {
  String className;
  StateAst stateAst;
  BuildAst buildAst;

  @override
  WidgetAst build() => new WidgetAst(
        className: className,
        stateAst: stateAst,
        buildAst: buildAst,
      );
}

/// State of a widget.
class StateAst extends Ast {
  @override
  void accept(AstVisitor visitor) {
    visitor.visitStateAst(this);
  }

  @override
  String toString([int indent = 0]) {
    return _indent('$runtimeType()', by: indent);
  }  
}

/// A build method.
class BuildAst extends Ast {
  @override
  void accept(AstVisitor visitor) {
    visitor.visitBuildAst(this);
  }

  @override
  String toString([int indent = 0]) {
    return _indent('$runtimeType()', by: indent);
  }  
}

String _indent(String s, {@required int by}) {
  return s.split('\n').map((line) => '  ' * by + line).join('\n');
}
