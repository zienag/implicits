// Copyright 2023 Yandex LLC. All rights reserved.

import Foundation
import MacroUtils
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct GeneralVisitorMacro: ExtensionMacro {
  public static func expansion(
    of _: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo _: [TypeSyntax],
    in _: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard let type = type.as(IdentifierTypeSyntax.self),
          let structDecl = declaration.as(StructDeclSyntax.self),
          let parameterClause = structDecl.genericParameterClause,
          parameterClause.parameters.count == 1,
          let stateType = parameterClause.parameters.first?.name
    else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: declaration,
          message: .error(
            "@GeneralVisitorMacro can only be applied to a structure with one generic type"
          )
        ),
      ])
    }

    let visitors = declaration.memberBlock.members
      .compactMap { $0.decl.as(VariableDeclSyntax.self) }
      .flatMap(\.bindings)
      .compactMap(Visitor.init)

    let visitorTypes = visitors.map(\.visitee.name.text)
    guard visitorTypes.count == Set(visitorTypes).count else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: declaration,
          message: .error(
            "There should be no repeating visitor types as variables of a struct"
          )
        ),
      ])
    }

    return try [
      ExtensionDeclSyntax("extension \(type)") {
        let implClassName = ExprSyntax(stringLiteral: "StatefulSyntaxVisitor")

        try buildImplementationClass(
          name: implClassName,
          stateType: stateType,
          visitors: visitors
        )
        try buildFactory(
          implClassName: implClassName,
          stateType: stateType,
          visitors: visitors
        )
        try buildLense(type: type, stateType: stateType, visitors: visitors)
      },
    ]
  }

  private static func buildImplementationClass(
    name: some ExprSyntaxProtocol,
    stateType: TokenSyntax,
    visitors: [Visitor]
  ) throws -> some DeclSyntaxProtocol {
    try ClassDeclSyntax("fileprivate final class \(name): SyntaxVisitor") {
      "var state: \(stateType)"

      for visitor in visitors {
        "var \(visitor.name): \(visitor.type)"
      }

      try InitializerDeclSyntax(modifiers: .required) {
        "state: \(stateType)"
        for visitor in visitors {
          "\(visitor.name): @escaping \(visitor.type)"
        }
      } body: {
        "self.state = state"

        for visitor in visitors {
          "self.\(visitor.name) = \(visitor.name)"
        }

        "super.init(viewMode: .fixedUp)"
      }

      for visitor in visitors {
        try FunctionDeclSyntax(
          "override func visit(_ node: \(visitor.visitee)) -> SyntaxVisitorContinueKind"
        ) {
          "visitGeneral(\(visitor.name), node)"
        }
      }
    }
  }

  private static func buildFactory(
    implClassName: some ExprSyntaxProtocol,
    stateType: TokenSyntax,
    visitors: [Visitor]
  ) throws -> some DeclSyntaxProtocol {
    try FunctionDeclSyntax(
      "fileprivate func makeVisitor(state: \(stateType)) -> \(implClassName)"
    ) {
      FunctionCallExprSyntax(callee: implClassName) {
        LabeledExprSyntax(label: "state", expression: ExprSyntax("state"))
        for visitor in visitors {
          LabeledExprSyntax(
            label: visitor.name.text,
            expression: ExprSyntax("\(raw: visitor.name.text)")
          )
        }
      }
    }
  }

  private static func buildLense(
    type: IdentifierTypeSyntax,
    stateType: TokenSyntax,
    visitors: [Visitor]
  ) throws -> some DeclSyntaxProtocol {
    let upStateType = IdentifierTypeSyntax(name: "UpState")

    let projectedVisitorType = IdentifierTypeSyntax(
      name: type.name,
      genericArgumentClause: GenericArgumentClauseSyntax(
        arguments: GenericArgumentListSyntax {
          GenericArgumentSyntax(argument: .type(TypeSyntax(upStateType)))
        }
      )
    )

    let buildClosure = { (visitor: Visitor) in
      ClosureExprSyntax(
        signature: ClosureSignatureSyntax(
          parameterClause: .simpleInput(parameters: "upState", "visitee")
        )
      ) {
        "\(visitor.name)(&upState[keyPath: kp], visitee)"
      }
    }

    return try FunctionDeclSyntax(
      name: "lense",
      genericParameterClause: GenericParameterClauseSyntax {
        GenericParameterSyntax(name: upStateType.name)
      },
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax {
          "_ kp: WritableKeyPath<\(upStateType), \(stateType)>"
        },
        returnClause: ReturnClauseSyntax(type: projectedVisitorType)
      )
    ) {
      try FunctionCallExprSyntax(
        callee: TypeExprSyntax(type: projectedVisitorType),
        trailingClosure: visitors.first.map(buildClosure),
        additionalTrailingClosures: {
          for visitor in visitors.dropFirst() {
            MultipleTrailingClosureElementSyntax(
              label: visitor.name,
              closure: buildClosure(visitor)
            )
          }
        }
      )
    }
  }

  private struct Visitor {
    let name: TokenSyntax
    let type: IdentifierTypeSyntax
    let visitee: IdentifierTypeSyntax

    init?(binding: PatternBindingSyntax) {
      guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
            let type = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.trimmed,
            let untypedVisitee = type.genericArgumentClause?.arguments.first,
            let visitee = untypedVisitee.argument.as(IdentifierTypeSyntax.self)?.trimmed
      else { return nil }

      self.name = name
      self.type = type
      self.visitee = visitee
    }
  }
}

@main
struct ImplicitsToolMacros: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    GeneralVisitorMacro.self,
  ]
}
