// Copyright 2024 Yandex LLC. All rights reserved.

import ImplicitsTool
import Testing

struct PublicInterfaceSerializationTests {
  @Test func `symbol serialization`() {
    check(initSymbol)
    check(staticSymbol)
    check(memberSymbol)
  }

  @Test func `interface serialization`() {
    check(interface)
  }

  @Test func `interface2 serialization`() {
    check(interface2)
  }

  @Test func `empty interface serialization`() {
    check(ImplicitModuleInterface(
      module: "EmptyModule", symbols: [], testableSymbols: [],
      definedKeypathKeys: [],
      reexportedModules: []
    ))
  }

  private func check(_ value: some Serializable & Equatable & Sendable) {
    checkSerialization(value)
  }
}

private let interface = ImplicitModuleInterface(
  module: "TestModule",
  symbols: [
    initSymbol,
  ],
  testableSymbols: [
    staticSymbol,
    memberSymbol,
  ],
  definedKeypathKeys: [
    .init(name: "myType", type: "MyType"),
  ],
  reexportedModules: ["Base"]
)

private let interface2 = ImplicitModuleInterface(
  module: "AnotherModule",
  symbols: [
    ImplicitModuleInterface.Symbol(
      info: .init(
        kind: .memberFunction(
          name: "anotherModuleFunction"
        ),
        parameters: [.init(name: "_", type: "ImplicitScope", hasDefaultValue: false)],
        namespace: .init([]),
        returnType: fooType,
        syntax: .init(file: "n_another_module.swift", line: 5, column: 1),
        file: "n_another_module.swift"
      ),
      requirements: [.init(kind: .type, name: "AnotherModuleStruct")]
    ),
  ],
  testableSymbols: [],
  definedKeypathKeys: [
    .init(name: "isLoggedIn", type: "Variable<Bool>"),
    .init(name: "urlOpener", type: "(URL) -> Void"),
  ],
  reexportedModules: []
)

private let fooType: TypeInfo = .init(
  namespace: .success(SymbolNamespace(["Bar", "Foo"])),
  description: "Bar.Foo",
  strictDescription: .success("Bar.Foo")
)

private let initSymbol = ImplicitModuleInterface.Symbol(
  info: .init(
    kind: .initializer(optional: true),
    parameters: [],
    namespace: .init([]),
    returnType: nil,
    syntax: .init(file: "test.swift", line: 1, column: 2),
    file: "test.swift"
  ),
  requirements: [.init(kind: .keyPath, name: "myType")]
)

private let staticSymbol = ImplicitModuleInterface.Symbol(
  info: .init(
    kind: .staticFunction(name: "staticFunc"),
    parameters: [.init(name: "arg1", type: "Arg1")],
    namespace: .init(["MyType"]),
    returnType: .init(
      namespace: .success(SymbolNamespace(["MyType"])),
      description: "MyType",
      strictDescription: .success("MyType")
    ),
    syntax: .init(file: "test.swift", line: 1, column: 2),
    file: "test.swift"
  ),
  requirements: nil
)

private let memberSymbol = ImplicitModuleInterface.Symbol(
  info: .init(
    kind: .memberFunction(name: "test"),
    parameters: [
      .init(name: "foo", type: "Foo", hasDefaultValue: true),
      .init(name: "bar", type: "Bar", hasDefaultValue: false),
    ],
    namespace: .init(["MyType"]),
    returnType: nil,
    syntax: .init(file: "test.swift", line: 3, column: 4),
    file: "test.swift"
  ),
  requirements: [.init(kind: .keyPath, name: "myType")]
)
