// Copyright 2023 Yandex LLC. All rights reserved.

import ImplicitsMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

private let testMacros: [String: Macro.Type] = [
  "implicits": ImplicitMacro.self,
  "withImplicits": WithImplicitsMacro.self,
]

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
      let c = __implicit_wrap_test_swift_1_9({ _ in 42 })
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
      let c = __implicit_wrap_test_swift_1_9({ _ in 42 })
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
      let c = __implicit_wrap_test_swift_1_9({ [weak self] scope in 42 })
      """,
      diagnostics: [],
      macros: testMacros
    )
  }
}
