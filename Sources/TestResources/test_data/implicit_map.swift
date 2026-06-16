@_spi(Unsafe)
import Implicits

private func entry() {
  // expected-error@+1 {{Unresolved requirements: UInt16, UInt8, [Int8]}}
  let scope = ImplicitScope()
  defer { scope.end() }

  if Bool.random() {
    // expected-error@+1 {{Writing to implicit scope without local 'ImplicitScope'}}
    Implicit.map(UInt8.self, to: Int8.self) { [implicits = testBagImplicits()] _ in
      let scope = ImplicitScope(with: implicits)
      defer { scope.end() }
      @Implicit() var v1: [Int8]
      return v1.first ?? 0
    }

    @Implicit()
    var v1: Int8
  } else {
    let scope = scope.nested()
    defer { scope.end() }

    // expected-note@+1 {{Previous declaration here}}
    Implicit.map(UInt16.self, to: Int16.self) { _ in 0 }

    // expected-error@+1 {{Redeclaring implicit 'Int16' in the same scope}}
    Implicit.map(UInt16.self, to: Int16.self) { _ in 0 }

    @Implicit()
    var v2: Int16
  }
}

private func testBagImplicits() -> Implicits {
  Implicits()
}
