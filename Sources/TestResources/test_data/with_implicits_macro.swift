@_spi(Unsafe)
import Implicits

private func basicUsage() {
  // expected-error@+1 {{Unresolved requirements: Int8, UInt8}}
  let scope = ImplicitScope()
  defer { scope.end() }

  _ = #withImplicits { scope in
    @Implicit() var v1: UInt8
  }

  _ = #withImplicits { (a: Int, b: String, scope) in
    @Implicit() var v1: Int8
    return "\(a): \(b)"
  }
}

private func missingScope() {
  // expected-error@+1 {{Using implicits without 'ImplicitScope'}}
  _ = #withImplicits { scope in
    @Implicit() var v1: Double
  }
}

private func underscoreScope() {
  // expected-error@+1 {{Unresolved requirement: Float}}
  let scope = ImplicitScope()
  defer { scope.end() }

  _ = #withImplicits { _ in
    @Implicit() var v1: Float
  }
}

private func parenthesizedSyntax() {
  // expected-error@+1 {{Unresolved requirement: Int16}}
  let scope = ImplicitScope()
  defer { scope.end() }

  _ = #withImplicits({ scope in
    @Implicit() var v1: Int16
  })
}

private func customScopeName() {
  let scope = ImplicitScope()
  defer { scope.end() }

  // expected-error@+1 {{#withImplicits closure's last parameter must be named 'scope' or '_'}}
  _ = #withImplicits { myScope in
    @Implicit() var v1: Int16
  }
}

#if NO_COMPILE
// Type inference fails for macro-expanded closures with capture lists
// https://github.com/swiftlang/swift/issues/86871
private func withCaptureList() {
  // expected-error@+1 {{Unresolved requirement: Int32}}
  let scope = ImplicitScope()
  defer { scope.end() }

  let x = 42
  _ = #withImplicits { [x] scope in
    @Implicit() var v1: Int32
    return x
  }
}
#endif

private func __implicit_wrap_with_implicits_macro_swift_9_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_13_7<A1, A2, T>(_ body: @escaping (A1, A2, ImplicitScope) -> T) -> (A1, A2) -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_21_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_31_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_41_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_51_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_65_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }

private func explicitNoIsolation() {
  // expected-error@+1 {{Unresolved requirement: Int64}}
  let scope = ImplicitScope()
  defer { scope.end() }

  _ = #withImplicits(isolation: .none) { scope in
    @Implicit() var v1: Int64
  }
}

private func explicitNoIsolationParenthesized() {
  // expected-error@+1 {{Unresolved requirement: UInt64}}
  let scope = ImplicitScope()
  defer { scope.end() }

  _ = #withImplicits(isolation: .none, { scope in
    @Implicit() var v1: UInt64
  })
}

private func explicitMainActor() {
  // expected-error@+1 {{Unresolved requirement: UInt16}}
  let scope = ImplicitScope()
  defer { scope.end() }

  _ = #withImplicits(isolation: .mainActor) { @MainActor scope in
    @Implicit() var v1: UInt16
  }
}

private func __implicit_wrap_with_implicits_macro_swift_85_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_95_7<T>(_ body: @escaping (ImplicitScope) -> T) -> () -> T { fatalError() }
private func __implicit_wrap_with_implicits_macro_swift_105_7<T>(_ body: @escaping @MainActor (ImplicitScope) -> T) -> @MainActor () -> T { fatalError() }
