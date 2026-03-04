import Implicits

private func entry() {
  // expected-error@+1 {{Unresolved requirements: F1, F2, F3, F4, F5, F6, F7}}
  let scope = ImplicitScope()
  defer { scope.end() }

  f2(f1(scope), scope)

  f3(f3a(scope))

  f4(scope)(0)

  if f5(scope) {
    _ = 0
  }

  _ = f6(scope) + f7(scope)

  lazy var _ = {
    // expected-error@+1 {{Unresolved requirement: F8}}
    let scope = ImplicitScope()
    defer { scope.end() }

    @Implicit()
    var v1: F8

    return 0
  }()
}

private struct LazyFields {
  lazy var lazyVar: F1 = {
    // expected-error@+1 {{Unresolved requirement: F1}}
    let scope = ImplicitScope()
    defer { scope.end() }

    return f1(scope)
  }()
}

// MARK: - Multiple trailing closures

private func multipleTrailingClosures() {
  multipleTrailingClosuresHelper {
    // expected-error@+1 {{Unresolved requirement: UInt8}}
    let scope = ImplicitScope()
    defer { scope.end() }
    @Implicit() var v: UInt8
  } second: {
    // expected-error@+1 {{Unresolved requirement: UInt16}}
    let scope = ImplicitScope()
    defer { scope.end() }
    @Implicit() var v: UInt16
  }
}

// MARK: - Helpers

private struct F1 {}
private func f1(_: ImplicitScope) -> F1 {
  @Implicit()
  var v1: F1

  return v1
}

private struct F2 {}
private func f2(_: F1, _: ImplicitScope) {
  @Implicit()
  var v1: F2
}

private struct F3 {}
private func f3a(_: ImplicitScope) -> F3 {
  @Implicit()
  var v1: F3

  return v1
}

private func f3(_: F3) {}

private struct F4 {}
private func f4(_: ImplicitScope) -> (Int) -> Void {
  @Implicit()
  var v1: F4

  return { _ in }
}

private struct F5 {}
private func f5(_: ImplicitScope) -> Bool {
  @Implicit()
  var v1: F5

  return false
}

private struct F6 {}
private func f6(_: ImplicitScope) -> Int {
  @Implicit()
  var v1: F6

  return 1
}

private struct F7 {}
private func f7(_: ImplicitScope) -> Int {
  @Implicit()
  var v1: F7

  return 1
}

private struct F8 {}
private func f8(_: ImplicitScope) -> Int {
  @Implicit()
  var v1: F7

  return 1
}

private func multipleTrailingClosuresHelper(first: () -> Void, second: () -> Void) {}
