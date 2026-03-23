// Copyright 2023 Yandex LLC. All rights reserved.

import Testing

struct StaticAnalysisTests {
  @Test func `syntax structure`() {
    verify(file: "syntax_structure.swift")
  }

  @Test func `basic graph`() {
    verify(file: "graph_basic.swift")
  }

  @Test func `nested scopes`() {
    verify(file: "nested_scope.swift")
  }

  @Test func recursion() {
    verify(file: "graph_recursion.swift")
  }

  @Test func `object scope`() {
    verify(file: "object_scope.swift")
  }

  @Test func `symbol resolution`() {
    verify(file: "symbol_resolution.swift")
  }

  @Test func `implicit bag`() {
    verify(file: "implicit_bag.swift")
  }

  @Test func `stored implicit bag`() {
    verify(file: "stored_implicit_bag.swift")
  }

  @Test func `implicit scope order`() {
    verify(file: "implicit_scope_order.swift")
  }

  @Test func `key resolving`() {
    verify(file: "key_resolving.swift")
  }

  @Test func expressions() {
    verify(file: "expressions.swift")
  }

  @Test func `implicit map`() {
    verify(file: "implicit_map.swift")
  }

  @Test func `with scope`() {
    verify(file: "with_scope.swift")
  }

  @Test func `with named implicits`() {
    verify(file: "with_named_implicits.swift")
  }

  @Test func `with implicits macro`() {
    verify(file: "with_implicits_macro.swift")
  }

  @Test func `generated init`() {
    verify(file: "generated_init.swift")
  }

  @Test func `type resolution`() {
    verify(file: "type_resolution.swift")
  }

  @Test func `multiple file resolution`() {
    verify(files: [
      "multiple_file_resolution_f1.swift",
      "multiple_file_resolution_f2.swift",
    ])
  }

  @Test func `using implicit interface`() {
    verify(
      files: [
        "using_implicit_interface.swift",
      ],
      dependencies: [anotherModule]
    )
  }

  @Test func `using testable implicit interface`() {
    verify(
      files: [
        "using_testable_implicit_interface.swift",
      ],
      dependencies: [anotherModule]
    )
  }

  @Test func exporting() {
    verify(file: "exporting.swift", enableExporting: true)
  }

  @Test func `support file`() {
    verify(
      files: ["support_file.swift"],
      enableExporting: true,
      supportFile: "support_file_snapshot.swift",
      dependencies: [
        (modulename: "AnotherModule", files: ["another_module.swift"]),
      ]
    )
  }

  @Test func `if config filtering`() {
    verify(file: "if_config_filtering.swift", compilationConditions: ["A", "B", "C"])
  }

  @Test func `if config code block`() {
    verify(file: "if_config_code_block.swift", compilationConditions: ["A", "B", "C"])
  }

  @Test func `immediate closure`() {
    verify(file: "immediate_closure.swift")
  }

  @Test func `requirements trace`() {
    verify(file: "graph_trace.swift", traceUnresolved: true)
  }
}

private let anotherModule = (modulename: "AnotherModule", files: ["another_module.swift"])
