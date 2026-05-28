// Copyright 2023 Yandex LLC. All rights reserved.

import ImplicitsMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

private let testMacros: [String: MacroSpec] = [
  "implicits": MacroSpec(type: ImplicitMacro.self),
  "withImplicits": MacroSpec(type: WithImplicitsMacro.self),
]

/// Bridges swift-syntax's macro-expansion assertions to Swift Testing.
/// The default `assertMacroExpansion` from `SwiftSyntaxMacrosTestSupport`
/// reports failures via `XCTFail`, which Swift Testing does not observe.
private func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macros: [String: MacroSpec],
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
    originalSource,
    expandedSource: expectedExpandedSource,
    diagnostics: diagnostics,
    macroSpecs: macros,
    failureHandler: { failure in
      Issue.record(
        Comment(rawValue: failure.message),
        sourceLocation: sourceLocation
      )
    }
  )
}

struct ImplicitMacroTests {
  @Test func `implicit macro`() {
    assertMacroExpansion(
      """
      let c = { [implictis = #implicits] in 42 }
      """,
      expandedSource: """
      let c = { [implictis = __implicit_bag_test_swift_1_24()] in 42 }
      """,
      diagnostics: [],
      macros: testMacros
    )
  }

  @Test func `with implicits macro`() {
    assertMacroExpansion(
      """
      let c = #withImplicits { _ in 42 }
      """,
      expandedSource: """
      let c = __implicit_wrap_test_swift_1_9({ _ in
              42
          })
      """,
      diagnostics: [],
      macros: testMacros
    )
  }

  @Test func `with implicits macro parenthesized syntax`() {
    assertMacroExpansion(
      """
      let c = #withImplicits({ _ in 42 })
      """,
      expandedSource: """
      let c = __implicit_wrap_test_swift_1_9({ _ in
              42
          })
      """,
      diagnostics: [],
      macros: testMacros
    )
  }

  @Test func `with implicits macro non closure argument`() {
    assertMacroExpansion(
      """
      let c = #withImplicits(someVariable)
      """,
      expandedSource: """
      let c = #withImplicits(someVariable)
      """,
      diagnostics: [
        DiagnosticSpec(message: "#withImplicits requires a closure argument", line: 1, column: 9)
      ],
      macros: testMacros
    )
  }

  @Test func `with implicits macro with capture list`() {
    assertMacroExpansion(
      """
      let c = #withImplicits({ [weak self] scope in 42 })
      """,
      expandedSource: """
      let c = __implicit_wrap_test_swift_1_9({ [weak self] scope in
              42
          })
      """,
      diagnostics: [],
      macros: testMacros
    )
  }

  @Test func `with implicits macro explicit isolation: .none`() {
    assertMacroExpansion(
      """
      let c = #withImplicits(isolation: .none) { _ in 42 }
      """,
      expandedSource: """
      let c = __implicit_wrap_test_swift_1_9({ _ in
              42
          })
      """,
      diagnostics: [],
      macros: testMacros
    )
  }

  @Test func `with implicits macro explicit isolation: .mainActor`() {
    assertMacroExpansion(
      """
      let c = #withImplicits(isolation: .mainActor) { @MainActor _ in 42 }
      """,
      expandedSource: """
      let c = __implicit_wrap_test_swift_1_9({ @MainActor _ in
              42
          })
      """,
      diagnostics: [],
      macros: testMacros
    )
  }
}
