import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

package struct SourceLocation<Node: FreestandingMacroExpansionSyntax> {
  package var fileName: String
  package var line: String
  package var column: String
  private var node: Node

  private var isInMacroExpansion: Bool {
    fileName.hasPrefix("@__swiftmacro_")
  }

  package init(
    of node: Node,
    in context: some MacroExpansionContext
  ) throws {
    guard let loc = context.location(of: node),
          let fileExpansion = loc.filename else {
      throw DiagnosticsError.at(node, "Unable to get source location")
    }
    let moduleAndFile = fileExpansion.split(separator: "/")
    guard let lastComponent = moduleAndFile.last else {
      throw DiagnosticsError.at(node, "Unable to get file name")
    }
    self.node = node
    self.fileName = String(lastComponent)
    self.line = loc.line.trimmedDescription
    self.column = loc.column.trimmedDescription
  }

  package func checkNotInMacroExpansion(_ macroName: String) throws {
    if isInMacroExpansion {
      throw DiagnosticsError.at(node, "#\(macroName) cannot be used inside macro expansion")
    }
  }
}

extension AbstractSourceLocation {
  var filename: String? {
    switch file.as(ExprSyntaxEnum.self) {
    case let .stringLiteralExpr(literal):
      literal.representedLiteralValue
    default:
      nil
    }
  }
}
