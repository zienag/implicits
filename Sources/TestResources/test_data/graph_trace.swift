import Implicits

private func `traces through call chain`() {
  // expected-error@+1 {{Unresolved requirement: UInt16}}
  let scope = ImplicitScope()
  defer { scope.end() }
  forward(scope) // expected-note {{Requires 'UInt16'}}
}

private func forward(_ scope: ImplicitScope) {
  requireUInt16(scope) // expected-note {{Requires 'UInt16'}}
}

private func `skips provided keys in trace`() {
  // expected-error@+1 {{Unresolved requirement: UInt64}}
  let scope = ImplicitScope()
  defer { scope.end() }
  @Implicit var v: UInt32 = 0
  requireU32U64(scope) // expected-note {{Requires 'UInt64'}}
}

private func `traces multiple keys through same call`() {
  // expected-error@+1 {{Unresolved requirements: Int8, UInt8}}
  let scope = ImplicitScope()
  defer { scope.end() }
  // expected-note@+2 {{Requires 'Int8'}}
  // expected-note@+1 {{Requires 'UInt8'}}
  requireI8U8(scope)
}

private func `traces different keys through different calls`() {
  // expected-error@+1 {{Unresolved requirements: Int16, Int32}}
  let scope = ImplicitScope()
  defer { scope.end() }
  requireInt16(scope) // expected-note {{Requires 'Int16'}}
  requireInt32(scope) // expected-note {{Requires 'Int32'}}
}

private func `no trace when all requirements resolved`() {
  let scope = ImplicitScope()
  defer { scope.end() }
  @Implicit var v1: Int8 = 0
  @Implicit var v2: UInt8 = 0
  requireI8U8(scope)
}

private func `traces only for unresolved entry point`() {
  // expected-error@+1 {{Unresolved requirements: Int8, UInt8}}
  let scope = ImplicitScope()
  defer { scope.end() }
  // expected-note@+2 {{Requires 'Int8'}}
  // expected-note@+1 {{Requires 'UInt8'}}
  requireI8U8(scope)
}

private func `same key required through multiple calls`() {
  // expected-error@+1 {{Unresolved requirement: Float}}
  let scope = ImplicitScope()
  defer { scope.end() }
  requireFloat1(scope) // expected-note {{Requires 'Float'}}
  requireFloat2(scope)
}

// MARK: - Helpers

private func requireUInt16(_: ImplicitScope) {
  @Implicit()
  var v: UInt16 // expected-note {{Requires 'UInt16'}}
}

private func requireU32U64(_: ImplicitScope) {
  @Implicit()
  var v1: UInt32
  @Implicit()
  var v2: UInt64 // expected-note {{Requires 'UInt64'}}
}

private func requireI8U8(_: ImplicitScope) {
  @Implicit()
  var v1: Int8 // expected-note {{Requires 'Int8'}}
  @Implicit()
  var v2: UInt8 // expected-note {{Requires 'UInt8'}}
}

private func requireInt16(_: ImplicitScope) {
  @Implicit()
  var v: Int16 // expected-note {{Requires 'Int16'}}
}

private func requireInt32(_: ImplicitScope) {
  @Implicit()
  var v: Int32 // expected-note {{Requires 'Int32'}}
}

private func requireFloat1(_: ImplicitScope) {
  @Implicit()
  var v: Float // expected-note {{Requires 'Float'}}
}

private func requireFloat2(_: ImplicitScope) {
  @Implicit()
  var v: Float
}
