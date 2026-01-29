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
  @Test func implicitMacro() {
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

  @Test func withImplicitsMacro() {
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
}
