// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'ast.dart';
import 'token.dart';

String emit(DxAst ast) {
  final emitter = new _Emitter();
  ast.accept(emitter);
  return new DartFormatter().format(emitter.lib.build().accept(new DartEmitter()).toString());
}

class _Context<T extends Ast> {
  _Context(this.node, this.context);

  final T node;
  final dynamic context;
}

class _Emitter implements AstVisitor {
  final lib = new FileBuilder();
  final List<_Context> _nodeStack = <_Context>[];

  void _push(Ast node, [dynamic context]) => _nodeStack.add(new _Context(node, context));

  _Context<T> _ancestorContext<T extends Ast>(bool predicate(_Context c), Object description) {
    if (_nodeStack.isEmpty) {
      throw new _EmitterException('Attempted to find $description in the context, but context stack was empty.');
    }

    return _nodeStack
      .reversed
      .skip(1)
      .firstWhere(predicate, orElse: () {
        throw new _EmitterException(
          '$description not found in the context stack. Current stack:\n'
          '\n'
          '${_nodeStack.map((c) => 'node: ${c.node.runtimeType}; context: ${c.context.runtimeType}').join('\n')}'
        );
      });
  }

  _Context _pop() => _nodeStack.removeLast();

  @override
  void visitDxAst(DxAst node) {
    _push(node);
    for (Ast child in node.children) {
      child.accept(this);
    }
    _pop();
  }

  @override
  void visitImportBlockAst(ImportBlockAst node) {
    _push(node);
    for (ImportAst child in node.children) {
      child.accept(this);
    }
    _pop();
  }

  @override
  void visitImportAst(ImportAst node) {
    _push(node);
    // First token in any import must be an identifier.
    final Identifier firstToken = node.pathTokens.first;
    String importUrl;
    if (node.pathTokens.length == 1) {
      // Desugar "foo" => "package:foo/foo.dart".
      importUrl = 'package:${firstToken.name}/${firstToken.name}.dart';
    } else if (node.pathTokens[1] == Punctuation.$colon) {
      // Assume a core library import, e.g. "dart:async".
      assert(node.pathTokens[0] == new Identifier('dart'));
      assert(node.pathTokens.length == 3);
      final Identifier lastToken = node.pathTokens.last;
      importUrl = 'dart:${lastToken.name}';
    } else {
      // Assume a package import with subpaths, e.g. "flutter/material",
      // which is desugared into "package:flutter/material.dart".
      final buf = new StringBuffer();
      final tokenIter = node.pathTokens.iterator;
      bool isFirst = true;
      while(tokenIter.moveNext()) {
        if (!isFirst) {
          buf.write('/');
        }
        final Identifier filePart = tokenIter.current;
        buf.write(filePart.name);
        if (tokenIter.moveNext()) {
          assert(tokenIter.current == Punctuation.$slash);
        }
        isFirst = false;
      }
      importUrl = 'package:${buf}.dart';
    }

    lib.directives.add(new Directive.import(importUrl));
    _pop();
  }

  @override
  void visitWidgetAst(WidgetAst node) {
    final widgetClass = new ClassBuilder()
      ..name = node.className;
    _push(node, widgetClass);
    final isStateless = node.stateAst == null;
    if (isStateless) {
      _generateStatelessWidget(node, widgetClass);
    } else {
      _generateStatefulWidget(node, widgetClass);
    }
    lib.body.add(widgetClass.build());
    if (!isStateless) {
      node.stateAst.accept(this);
    }
    _pop();
  }

  void _generateStatelessWidget(WidgetAst node, ClassBuilder widgetClass) {
    widgetClass.extend = new Reference('StatelessWidget');
    node.buildAst.accept(this);
  }

  void _generateStatefulWidget(WidgetAst node, ClassBuilder widgetClass) {
    widgetClass.extend = new Reference('StatefulWidget');
    final createStateMethod = new MethodBuilder()
      ..name = 'createState'
      ..annotations.add(_overridesAnnotation)
      ..body = new Reference('${node.className}State').newInstance(const []).expression.returned.statement;
    widgetClass.methods.add(createStateMethod.build());
  }

  @override
  void visitStateAst(StateAst node) {
    final stateClass = new ClassBuilder();
    _push(node, stateClass);
    final widget = _ancestorContext<WidgetAst>((c) => c.node is WidgetAst, WidgetAst).node;
    stateClass
      ..name = '${widget.className}State'
      ..extend = (new TypeReferenceBuilder()
        ..symbol = 'State'
        ..types.add(new Reference('${widget.className}'))
      ).build();

    widget.buildAst.accept(this);
    lib.body.add(stateClass.build());
    _pop();
  }

  @override
  void visitBuildAst(BuildAst node) {
    _push(node);
    final ClassBuilder enclosingClass = _ancestorContext((c) => c.context is ClassBuilder, ClassBuilder).context;
    final buildMethod = new MethodBuilder()
      ..name = 'build'
      ..annotations.add(_overridesAnnotation);
    enclosingClass.methods.add(buildMethod.build());
    _pop();
  }
}

Annotation _overridesAnnotation = () {
  final builder = new AnnotationBuilder();
  builder.code = new Reference('override').code;
  return builder.build();
}();

class _EmitterException {
  _EmitterException(this.message);

  final String message;

  @override
  String toString() => '${runtimeType}: ${message}';
}
