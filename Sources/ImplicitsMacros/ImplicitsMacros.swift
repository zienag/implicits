// Copyright 2023 Yandex LLC. All rights reserved.

import ImplicitsShared
import MacroUtils
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ImplicitMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let loc = try SourceLocation(of: node, in: context)
    try loc.checkNotInMacroExpansion("implicits")
    let funcName = generateImplicitBagFuncName(
      filename: loc.fileName,
      line: loc.line,
      column: loc.column
    )
    return "\(raw: funcName)()"
  }
}

public struct WithImplicitsMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let loc = try SourceLocation(of: node, in: context)
    try loc.checkNotInMacroExpansion("withImplicits")

    // The closure body is the trailing closure when present, otherwise the
    // last positional argument (an explicit isolation marker, if passed,
    // precedes it).
    let closure: ClosureExprSyntax
    if let trailingClosure = node.trailingClosure {
      closure = trailingClosure
    } else if let lastArg = node.arguments.last,
              let closureExpr = lastArg.expression.as(ClosureExprSyntax.self) {
      closure = closureExpr
    } else {
      throw DiagnosticsError.at(node, "#withImplicits requires a closure argument")
    }

    let funcName = generateImplicitWrapFuncName(
      filename: loc.fileName,
      line: loc.line,
      column: loc.column
    )
    return "\(raw: funcName)(\(closure))"
  }
}

@main
struct ImplicitsToolMacros: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ImplicitMacro.self,
    WithImplicitsMacro.self,
  ]
}
