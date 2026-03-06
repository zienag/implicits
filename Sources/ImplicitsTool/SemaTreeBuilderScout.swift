// Copyright 2024 Yandex LLC. All rights reserved.

extension SemaTreeBuilder {
  /// Scout looks ahead in the syntax tree and collects information for further analysis.
  enum Scout {
    struct Result {
      var symbols: [(Symbol, Visibility)]
      var failedInitializers: [(SymbolNamespace, [PreDiagnostic<Syntax>])]

      init(
        symbols: [(Symbol, Visibility)] = [],
        failedInitializers: [(SymbolNamespace, [PreDiagnostic<Syntax>])] = []
      ) {
        self.symbols = symbols
        self.failedInitializers = failedInitializers
      }

      mutating func merge(_ other: Result) {
        symbols += other.symbols
        failedInitializers += other.failedInitializers
      }

      static func +=(lhs: inout Result, rhs: Result) {
        lhs.merge(rhs)
      }

      func namespaced(_ name: String) -> Self {
        namespaced([name])
      }

      func namespaced(_ namespace: [String]) -> Self {
        var copy = self
        copy.symbols = symbols.map { ($0.0.namespaced(namespace), $0.1) }
        copy.failedInitializers = failedInitializers.map {
          var copy = $0
          copy.0.value.insert(contentsOf: namespace, at: 0)
          return copy
        }
        return copy
      }
    }

    static func lookaheadModule(
      _ module: [File],
      scope: Scope,
      dependencies: SemaTreeBuilder.Dependencies
    ) -> Result {
      module.reduce(into: Result()) { acc, file in
        acc += lookaheadFile(
          file.content, file: file.name,
          scope: scope, dependencies: dependencies
        )
      }
    }

    static func lookaheadFile(
      _ statements: [SXT.TopLevelEntity], file: String, scope: Scope,
      dependencies: SemaTreeBuilder.Dependencies
    ) -> Result {
      statements.reduce(into: Result()) { acc, statement in
        acc += lookaheadToplevel(
          statement, scope: scope, file: file, dependencies: dependencies
        )
      }
    }

    static func lookaheadToplevel(
      _ item: SXT.TopLevelEntity, scope: Scope, file: String,
      dependencies: SemaTreeBuilder.Dependencies
    ) -> Result {
      switch item.value {
      case let .declaration(declaration):
        lookaheadDeclaration(
          declaration, syntax: item.syntax, scope: scope, file: file,
          defaultVisibility: nil
        )
      case let .extension(ext):
        lookaheadExtension(ext, scope: scope.nested, file: file)
      case let .import(decl):
        if scope.importsVisible, let dep = dependencies[decl.moduleName] {
          Result(symbols: (
            dep.symbols + dep.reexports.flatMap {
              dependencies[$0]?.symbols ?? []
            } + (decl.attributes.contains(where: \.isTestable) ? dep.testableSymbols : [])
          ).map { ($0, .public) })
        } else {
          Result()
        }
      case let .ifConfig(ifConfig):
        ifConfig.clauses.reduce(into: Result()) { acc, clause in
          acc += clause.body.reduce(into: Result()) { acc, entity in
            acc += lookaheadToplevel(
              entity, scope: scope, file: file, dependencies: dependencies
            )
          }
        }
      }
    }

    static func lookaheadExtension(
      _ item: SXT.Extension, scope: Scope, file: String
    ) -> Result {
      guard let namespace = item.extendedType.componentsWithoutGenerics() else {
        return Result()
      }
      return lookaheadMemberBlock(
        item.members, scope: scope, file: file,
        defaultVisibility: item.visibility.extensionMemberVisibility()
      ).namespaced(namespace)
    }

    static func lookaheadDeclaration(
      _ item: SXT.Declaration, syntax: Syntax, scope: Scope, file: String,
      defaultVisibility: Visibility?
    ) -> Result {
      var result = Result()
      switch item {
      case let .function(f):
        let effectiveVisibility =
          f.visibility.ifDefault(use: defaultVisibility)
        guard scope.includes(effectiveVisibility) else { break }
        let name = f.name
        let kind: Symbol.Kind = f.affiliation.isStaticLike ?
          .staticFunction(name: name) : .memberFunction(name: name)
        let symbol = Symbol(
          kind: kind,
          parameters: f.parameters.map {
            Symbol.Parameter(
              name: $0.signatureName, type: $0.type.value.description,
              hasDefaultValue: $0.hasDefaultValue
            )
          },
          returnType: f.returnTypeNamespace(),
          syntax: syntax, file: file
        )
        result.symbols.append((symbol, effectiveVisibility))
      case .protocol:
        break
      case let .memberBlock(memberBlock):
        result += lookaheadMemberBlock(
          memberBlock, scope: scope, file: file,
          defaultVisibility: defaultVisibility
        )
      case let .type(type):
        result += lookaheadType(type, scope: scope, file: file, syntax: syntax)
      case let .variable(variable):
        _ = variable // not implemented
      }
      return result
    }

    static func lookaheadType(
      _ type: SXT.TypeDecl, scope: Scope, file: String, syntax: Syntax
    ) -> Result {
      guard scope.includes(type.visibility) else { return Result() }
      let namespace = type.name
      var result = lookaheadMemberBlock(
        type.members, scope: scope.nested, file: file,
        defaultVisibility: nil
      )
      let hasInitializer = type.members.contains(where: \.value.isInitializer)

      if !hasInitializer {
        let initializer = type.synthesizeInitializer(file: file, syntax: syntax)
        switch initializer {
        case let .success(initializer):
          if scope.includes(initializer.visibility) {
            result.symbols.append((initializer.symbol, initializer.visibility))
          }
        case let .failure(diags):
          result.failedInitializers.append((.init([]), diags))
        case nil:
          break
        }
      }

      return result.namespaced(namespace)
    }

    static func lookaheadMemberBlock(
      _ members: SXT.MemberBlock, scope: Scope, file: String,
      defaultVisibility: Visibility?
    ) -> Result {
      var result = Result()
      for item in members {
        switch item.value {
        case let .initializer(initializer):
          let effectiveVisibility =
            initializer.visibility.ifDefault(use: defaultVisibility)
          guard scope.includes(effectiveVisibility) else { break }
          result.symbols.append((.initializer(
            params: initializer.parameters.map {
              .init(
                name: $0.signatureName, type: $0.type.value.description,
                hasDefaultValue: $0.hasDefaultValue
              )
            },
            optional: initializer.optional,
            syntax: item.syntax,
            file: file
          ), effectiveVisibility))
        case let .declaration(decl):
          result += lookaheadDeclaration(
            decl, syntax: item.syntax, scope: scope, file: file,
            defaultVisibility: defaultVisibility
          )
        }
      }
      return result
    }
  }
}

struct Scope {
  private enum Internal {
    case external
    case module
    case file
    case fileNested
    case type
  }

  private var impl: Internal

  static let external = Scope(impl: .external)
  static let module = Scope(impl: .module)
  static let file = Scope(impl: .file)
  static let type = Scope(impl: .type)

  var nested: Scope {
    switch impl {
    case .external:
      .external
    case .module:
      .module
    case .file:
      Scope(impl: .fileNested)
    case .fileNested:
      self
    case .type:
      self
    }
  }

  var importsVisible: Bool {
    switch impl {
    case .module, .external, .type: false
    case .file, .fileNested: true
    }
  }

  func includes(_ visibility: Visibility) -> Bool {
    switch impl {
    case .external:
      visibility.moreOrEqualVisible(than: .package)
    case .module:
      visibility.moreOrEqualVisible(than: .internal)
    case .file:
      visibility.moreOrEqualVisible(than: .private)
    case .fileNested:
      visibility.moreOrEqualVisible(than: .fileprivate)
    case .type:
      visibility.moreOrEqualVisible(than: .private)
    }
  }
}

private enum Result<T, S> {
  case success(T)
  case failure([PreDiagnostic<S>])
}

private typealias SynthesisResult<S> =
  Result<(symbol: SymbolInfo<S>, visibility: Visibility), S>

extension SyntaxTree.TypeDecl {
  fileprivate func synthesizeInitializer(
    file: String, syntax: Syntax
  ) -> SynthesisResult<Syntax>? {
    var parameters = [SymbolInfo<Syntax>.Parameter]()
    var failures = [PreDiagnostic<Syntax>]()
    for member in members {
      switch member.value {
      case let .declaration(.variable(v)):
        switch v.effectiveInitParameters() {
        case let .success(params):
          parameters += params
        case let .failure(diags):
          failures += diags
        }
      case .initializer, .declaration(.function),
           .declaration(.memberBlock), .declaration(.protocol),
           .declaration(.type):
        break
      }
    }
    if !failures.isEmpty {
      return .failure(failures)
    }
    let synthInit: SynthesisResult<Syntax>?
    switch kind {
    case .class, .actor:
      let hasSynthInit = parameters.allSatisfy(\.hasDefaultValue)
      // If parent class defines empty initializer,
      // synthezied initializer will be public.
      // As we don't have parent class information here,
      // we assume that synthesized initializer is public.
      synthInit = hasSynthInit ? .success((.initializer(
        params: [], optional: false, syntax: syntax, file: file
      ), .public)) : nil
    case .struct:
      synthInit = .success((.initializer(
        params: parameters,
        optional: false,
        syntax: syntax,
        file: file
      ), .internal))
    case .enum:
      synthInit = nil
    }
    return synthInit
  }
}

private typealias InitParamsResult<S> = Result<[SymbolInfo<S>.Parameter], S>

extension SyntaxTree.VariableDecl {
  fileprivate func effectiveInitParameters() -> InitParamsResult<Syntax> {
    typealias Param = SymbolInfo<Syntax>.Parameter
    var params = [SymbolInfo<Syntax>.Parameter]()
    var errors = [PreDiagnostic<Syntax>]()
    for binding in bindings {
      if let accessors = binding.accessorBlock, accessors.isCalculatable {
        continue
      }
      switch binding.name {
      case let .identifier(id):
        // FIXME: Handle this case
        // ```
        // struct S {
        //   var x = 0
        // }
        // @Implicit
        // let s = S() // ok
        // let s2 = S(x: 1) // unresolved, it's hard and not needed to resolve x
        // ```
        // To handle it, we need to rework parameter types in `SymbolInfo`
        // (optional?)
        guard let type = binding.type else {
          if binding.initializer == nil {
            errors.append(.error(.noExplicitType, at: binding.syntax))
          }
          continue
        }
        let hasDefaultValue = binding.initializer != nil || type.defaultsToNil
        params.append(
          Param(
            name: id,
            type: type.description,
            hasDefaultValue: hasDefaultValue
          )
        )
      case .tuple:
        errors.append(.error(.tupleVariable, at: binding.syntax))
      case .wildcard:
        break
      case .unsupported:
        errors.append(.error(.unsupportedSyntax, at: binding.syntax))
      }
    }
    return errors.isEmpty ? .success(params) : .failure(errors)
  }
}

extension DiagnosticMessage {
  static let noExplicitType = unableToSynthesize(" without explicit type")
  static let tupleVariable = unableToSynthesize(" with tuple member variable")
  static let unsupportedSyntax = unableToSynthesize(", unsupported syntax")

  private static func unableToSynthesize(_ message: String) -> Self {
    "Unable to synthesize initializer\(message)"
  }
}

extension SyntaxTree.TypeModel {
  var defaultsToNil: Bool {
    switch self {
    case .optional, .unwrappedOptional:
      true
    default:
      false
    }
  }
}

extension SyntaxTree.Attribute {
  var isTestable: Bool {
    self.simpleIdentifier == "testable" && self.arguments == nil
  }
}
