// Copyright 2025 Yandex LLC. All rights reserved.

import SwiftSyntax

/// Represents the effects (async/throwing) and type attributes of a closure used in named
/// implicits wrappers.
public struct ClosureEffects<Syntax> {
  public var isAsync: Bool
  public var isThrowing: Bool
  public var typeAttributes: [SyntaxTree<Syntax>.TypeModel]

  static var none: Self { Self(isAsync: false, isThrowing: false, typeAttributes: []) }

  var typeAttributesSyntax: AttributeListSyntax {
    AttributeListSyntax {
      for typeModel in typeAttributes {
        AttributeSyntax(attributeName: TypeSyntax("\(raw: typeModel.description)"))
      }
    }
  }

  /// Returns effect specifiers syntax for use in function types.
  var effectSpecifiers: TypeEffectSpecifiersSyntax? {
    guard isAsync || isThrowing else { return nil }
    return TypeEffectSpecifiersSyntax(
      asyncSpecifier: isAsync ? .keyword(.async) : nil,
      throwsClause: isThrowing ? ThrowsClauseSyntax(throwsSpecifier: .keyword(.throws)) : nil
    )
  }

  /// Wraps a function call expression with `try` and/or `await` as needed based on effects.
  func wrapCall(_ call: FunctionCallExprSyntax) -> ExprSyntax {
    var expr = ExprSyntax(call)
    if isAsync {
      expr = ExprSyntax(AwaitExprSyntax(expression: expr))
    }
    if isThrowing {
      expr = ExprSyntax(TryExprSyntax(expression: expr))
    }
    return expr
  }

  func mapSyntax<S>(_ transform: (Syntax) -> S) -> ClosureEffects<S> {
    ClosureEffects<S>(
      isAsync: isAsync,
      isThrowing: isThrowing,
      typeAttributes: typeAttributes.map { $0.mapSyntax(transform) }
    )
  }
}
