# Implicits Usage Guide for AI Assistants

This project uses Implicits - a Swift library for implicit parameter passing through call stacks. Eliminates "parameter drilling" - passing same arguments through multiple function layers.

## Core Pattern

```swift
func start() {
  let scope = ImplicitScope()
  defer { scope.end() }
  @Implicit var network = NetworkService()  // declare
  process(scope)
}

func process(_ scope: ImplicitScope) { fetch(scope) }

func fetch(_ scope: ImplicitScope) {
  @Implicit var network: NetworkService  // retrieve
  network.request()
}
```

**Rules:**
- `ImplicitScope` — last argument without parameter label
- Always `defer { scope.end() }` after creating scope
- Declaration: `@Implicit var x = value` (with initializer)
- Retrieval: `@Implicit var x: Type` (no initializer, explicit type)
- Missing implicit = compile-time error

## Keys: Type-Based vs Named

**Type-based (default)** — type is the key:
```swift
@Implicit var network: NetworkService
```

**Named keys** — use when type alone doesn't explain meaning:
```swift
extension ImplicitsKeys {
  static let guestMode = Key<Bool>()
}

@Implicit(\.guestMode) var guest = true   // declare
@Implicit(\.guestMode) var isGuest: Bool  // retrieve
```

## Nested Scopes

Child scope inherits parent values, can override or add new (retrieval picks nearest):
```swift
func inner(_ outer: ImplicitScope) async {
  let scope = outer.nested()
  defer { scope.end() }

  @Implicit var extra = ExtraService()  // added in this scope
  await extra.doWork(scope)
}
```

Note: async code is supported.

## Closures

Closures don't inherit scope — `#withImplicits` captures implicits used in body:
```swift
fetchData(completion: #withImplicits { result, scope in
  @Implicit var handler: ResultHandler
  handler.process(result)
})
```

## Factory Pattern

Store context for later use:
```swift
class Component {
  let implicits = #implicits

  init(_ scope: ImplicitScope) {}

  func createChild() -> Child {
    withScope(with: implicits) { scope in
      Child(scope)
    }
  }
}
```

## Stored Properties in Types

`@Implicit` works as stored property — type needs scope in initializer:
```swift
struct View {
  @Implicit var theme: Theme

  init(_ scope: ImplicitScope) {}
}
```

## Init/Defer Alternative

`withScope` handles scope lifecycle. When indentation is not a problem and the body is fairly small:
```swift
withScope { scope in ... }                    // Root scope
withScope(with: implicits) { scope in ... }   // From captured implicits
withScope(nesting: outer) { scope in ... }    // Nested scope
```

## Build-Time Analysis Setup

Add plugin to Package.swift:
```swift
.target(
  name: "MyApp",
  dependencies: [.product(name: "Implicits", package: "implicits")],
  plugins: [.plugin(name: "ImplicitsAnalysisPlugin", package: "implicits")]
)
```

**Plugin graph rule:** Every module on the path from your code to the Implicits library must have the plugin. Example: if `App → FeatureA → FeatureB → Implicits` and FeatureB uses implicits, then FeatureB and FeatureA both need the plugin (App too if it uses implicits).

## Static Analysis Constraints

1. **Type annotations may be needed** for type-based keys — analyzer infers when possible
2. **No dynamic dispatch** — analyzer can't track through protocol-typed values or closures stored in properties. Static calls only.
