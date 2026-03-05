// Copyright 2024 Yandex LLC. All rights reserved.

/// The `Automaton` represents a finite state machine used to match sequences of elements.
///
/// Unlike a typical finite state machine (FSM), this automaton supports multiple patterns and acts
/// similarly
/// to a trie. Each pattern has an associated value, and matching a sequence returns a list of all
/// values
/// associated with the patterns that match, rather than just a boolean result.
///
/// **Example Usage:**
/// ```swift
/// var automaton = Automaton<String, Int>()
///
/// // Add a pattern: exact sequence "a", "b", "c" with value 1
/// automaton.addPattern(
///   .sequence([
///     .exact("a"),
///     .exact("b"),
///     .exact("c")
///   ]),
///   value: 1
/// )
///
/// // Add a pattern: "a", optional "b", "c" with value 2
/// automaton.addPattern(
///   .sequence([
///     .exact("a"),
///     .optional(.exact("b")),
///     .exact("c")
///   ]),
///   value: 2
/// )
///
/// // Matching sequences
/// automaton.match(["a", "b", "c"]) // Returns [1, 2]
/// automaton.match(["a", "c"])      // Returns [2]
/// ```
public struct Automaton<T: Hashable, Value> {
  /// A pattern is a sequence of transitions that should be matched in order.
  public enum Pattern {
    /// Matches a sequence of transitions.
    case sequence([Pattern])
    /// Matches a single transition, which may or may not be present.
    indirect case optional(Pattern)
    /// Matches a sequence of transitions, which may or may not be present.
    indirect case zeroOrMore(Pattern)
    /// Matches a single transition, which matched exactly.
    case exact(T)
  }

  private struct Node {
    var transitions = [T: Set<Int>]()
    var epsilonTransitions = Set<Int>()
    var values = [Value]()
  }

  private var store = [Node()]

  public init() {}

  /// Adds a new pattern to the automaton with the specified value.
  public mutating func addPattern(_ pattern: Pattern, value: Value) {
    func addPatternRecursively(_ pattern: Pattern, previous: inout Set<Int>) {
      switch pattern {
      case let .exact(transition):
        let node = store.count
        store.append(Node())
        for p in previous {
          store[p].transitions[transition, default: []].insert(node)
        }
        previous = [node]
      case let .optional(subPattern):
        var optionalNodes = previous
        addPatternRecursively(subPattern, previous: &optionalNodes)
        previous.formUnion(optionalNodes)
      case let .zeroOrMore(subPattern):
        var zeroOrMoreNodes = previous
        addPatternRecursively(subPattern, previous: &zeroOrMoreNodes)
        for node in zeroOrMoreNodes {
          store[node].epsilonTransitions.formUnion(previous)
        }
        previous.formUnion(zeroOrMoreNodes)
      case let .sequence(subPatterns):
        for subPattern in subPatterns {
          addPatternRecursively(subPattern, previous: &previous)
        }
      }
    }
    var previous: Set = [0]
    addPatternRecursively(pattern, previous: &previous)
    for node in previous {
      store[node].values.append(value)
    }
  }

  /// Matches the specified sequence and returns a list of values associated with the matching
  /// patterns
  public func match(_ input: some Sequence<T>) -> [Value] {
    // Collect all possible NFA states from the start (including epsilon closure)
    var currentStates = epsilonClosure([0])
    // Move through each symbol
    for symbol in input {
      var nextStates = Set<Int>()
      for s in currentStates {
        // Follow real transitions
        if let destinations = store[s].transitions[symbol] {
          nextStates.formUnion(destinations)
        }
      }
      // Expand epsilon closure after each symbol
      currentStates = epsilonClosure(nextStates)
    }
    // Gather values from all reachable states
    var result = [Value]()
    for s in currentStates {
      result.append(contentsOf: store[s].values)
    }
    return result
  }

  // Compute epsilon closure for a set of states
  private func epsilonClosure(_ states: Set<Int>) -> Set<Int> {
    var stack = Array(states)
    var closure = states
    while let top = stack.popLast() {
      for eps in store[top].epsilonTransitions {
        if !closure.contains(eps) {
          closure.insert(eps)
          stack.append(eps)
        }
      }
    }
    return closure
  }
}

extension Automaton.Pattern: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Self...) {
    self = .sequence(elements)
  }

  @_disfavoredOverload
  public static func optional(_ transition: T) -> Automaton.Pattern {
    .optional(.exact(transition))
  }
}
