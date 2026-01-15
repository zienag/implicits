// Copyright 2025 Yandex LLC. All rights reserved.

import SwiftSyntax

/// Represents the effects (async/throwing) of a closure used in named implicits wrappers.
public struct ClosureEffects: Equatable, Sendable {
  public var isAsync: Bool
  public var isThrowing: Bool

  static let none = Self(isAsync: false, isThrowing: false)

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
}
