// Copyright 2023 Yandex LLC. All rights reserved.

/// Represents visibility of variable or object declaration.
/// `default` value is used when no visibility keyword provided.
/// ```
/// private class Foo { ... }
public enum Visibility: Hashable {
  case `default`
  case `private`
  case `fileprivate`
  case `internal`
  case package
  case `public`
  case open

  func moreOrEqualVisible(than other: Visibility) -> Bool {
    visibilityRelation >= other.visibilityRelation
  }

  func lessOrEqualVisible(than other: Visibility) -> Bool {
    visibilityRelation <= other.visibilityRelation
  }

  func ifDefault(
    use defaultVisibility: Visibility?
  ) -> Visibility {
    self == .default ? defaultVisibility ?? self : self
  }

  func extensionMemberVisibility() -> Visibility {
    switch self {
    case .private, .fileprivate:
      .fileprivate
    case .internal, .default, .public, .open, .package:
      self
    }
  }

  var visibilityRelation: Int {
    switch self {
    case .private: 0
    case .fileprivate: 1
    case .internal, .default: 2
    case .package: 3
    case .public, .open: 4
    }
  }
}
