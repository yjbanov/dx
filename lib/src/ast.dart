// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Common super-class of all AST node classes.
///
/// An AST node is a deeply immutable data structure.
@immutable
abstract class Ast {
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
    @required this.path,
  });

  final String path;

  @override
  String toString([int indent = 0]) {
    return _indent('$runtimeType($path)', by: indent);
  }  
}

class ImportAstBuilder extends AstBuilder<ImportAst> {
  final StringBuffer _path = new StringBuffer();

  void append(String part) {
    _path.write(part);
  }

  ImportAst build() => new ImportAst(path: _path.toString());
}

class ImportBlockAst extends AstWithChildren<ImportAst> {
  ImportBlockAst({List<ImportAst> children}) : super(children: children);

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
    this.stateAst,
    @required this.buildAst,
  });

  final StateAst stateAst;
  final BuildAst buildAst;

  @override
  String toString([int indent = 0]) {
    final buf = new StringBuffer('$runtimeType(\n');
    if (stateAst != null) {
      buf.writeln('  state:\n${stateAst.toString(indent + 1)}');
    }
    buf.writeln('  build:\n${buildAst.toString(indent + 1)}');
    buf.write(')');
    return _indent(buf.toString(), by: indent);
  }  
}

class WidgetAstBuilder extends AstBuilder<WidgetAst> {
  StateAst stateAst;
  BuildAst buildAst;

  @override
  WidgetAst build() => new WidgetAst(
        stateAst: stateAst,
        buildAst: buildAst,
      );
}

/// State of a widget.
class StateAst extends Ast {
  @override
  String toString([int indent = 0]) {
    return _indent('$runtimeType()', by: indent);
  }  
}

/// A build method.
class BuildAst extends Ast {
  @override
  String toString([int indent = 0]) {
    return _indent('$runtimeType()', by: indent);
  }  
}

String _indent(String s, {@required int by}) {
  return s.split('\n').map((line) => '  ' * by + line).join('\n');
}
