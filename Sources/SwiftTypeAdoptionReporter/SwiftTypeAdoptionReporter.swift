// Copyright 2020 Thumbtack, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Basic
import Foundation
import SPMUtility
import SwiftSyntax

public class SwiftTypeAdoptionReporter {
    /**
     * Return formatted report on the adoption of the specified types in the input source(s).
     *
     * - Parameters:
     *   - componentIdentifiers: List of Swift type names for which to measure adoption.
     *   - paths: List of files/directories in which to search.
     *   - moduleName: Name of module containing types, to ensure types referenced
     *                  by <module name>.<type name> are counted.
     *   - verbose: If true, print additional information about source as it is parsed.
     */
    public static func report(_ componentIdentifiers: [String],
                              for paths: [AbsolutePath],
                              moduleName: String? = nil,
                              verbose: Bool = false) throws -> String {
        var reporter = SwiftTypeAdoptionReporter(
            componentIdentifiers: componentIdentifiers,
            moduleName: moduleName,
            verbose: verbose
        )

        for path in paths {
            try visit(fileOrDirectory: path, with: &reporter)
        }

        return reporter.generate()
    }

    /**
     * Return formatted report on the adoption of the specified types in the input source(s).
     *
     * - Parameters:
     *   - componentIdentifiers: List of Swift type names for which to measure adoption.
     *   - sourceStrings: List of strings directly containing Swift source code.
     *   - moduleName: Name of module containing types, to ensure types referenced
     *                  by <module name>.<type name> are counted.
     *   - verbose: If true, print additional information about source as it is parsed.
     */
    public static func report(_ componentIdentifiers: [String],
                              for sourceStrings: [String],
                              moduleName: String? = nil,
                              verbose: Bool = false) throws -> String {
        var reporter = SwiftTypeAdoptionReporter(
            componentIdentifiers: componentIdentifiers,
            moduleName: moduleName,
            verbose: verbose
        )

        for sourceString in sourceStrings {
            try visit(sourceString: sourceString, with: &reporter)
        }

        return reporter.generate()
    }

    /**
     * Return adoption statistics for each of the specified types in the input source(s).
     *
     * - Parameters:
     *   - componentIdentifiers: List of Swift type names for which to measure adoption.
     *   - sourceStrings: List of strings directly containing Swift source code.
     *   - moduleName: Name of module containing types, to ensure types referenced
     *                  by <module name>.<type name> are counted.
     *   - verbose: If true, print additional information about source as it is parsed.
     */
    public static func reportRaw(_ componentIdentifiers: [String],
                              for sourceStrings: [String],
                              moduleName: String? = nil,
                              verbose: Bool = false) throws -> [String: Int] {
        var reporter = SwiftTypeAdoptionReporter(
            componentIdentifiers: componentIdentifiers,
            moduleName: moduleName,
            verbose: verbose
        )

        for sourceString in sourceStrings {
            try visit(sourceString: sourceString, with: &reporter)
        }

        return reporter.usageCounts
    }

    public enum Error: Swift.Error {
        case noSuchFileOrDirectory
    }

    // MARK: - Private
    private var usageCounts: [String: Int] = [:]
    private let componentIdentifiers: [String]
    private let moduleName: String?
    private let verbose: Bool

    private init(componentIdentifiers: [String],
                 moduleName: String? = nil,
                 verbose: Bool) {
        self.componentIdentifiers = componentIdentifiers
        self.moduleName = moduleName
        self.verbose = verbose
    }

    private func generate() -> String {
        let sortedUsageCounts = usageCounts.sorted(by: { $0.key < $1.key })

        var output = ""
        for (componentName, usageCount) in sortedUsageCounts {
            output += "\(componentName) used \(usageCount) time\(usageCount != 1 ? "s" : "").\n"
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /**
    * - Parameters:
    *   - fileOrDirectory: Path of file/directory to parse.
    *   - reporter: Reporter in which to store report.
    */
    private static func visit(fileOrDirectory: AbsolutePath, with reporter: inout SwiftTypeAdoptionReporter) throws {
        let isDirectoryPointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        guard FileManager.default.fileExists(atPath: fileOrDirectory.pathString, isDirectory: isDirectoryPointer) else {
            throw Error.noSuchFileOrDirectory
        }

        if isDirectoryPointer.pointee.boolValue {
            let directory = fileOrDirectory
            let directoryPath = directory.pathString

            let fileEnumerator = FileManager.default.enumerator(atPath: directoryPath)
            while let fileName = fileEnumerator?.nextObject() as? String {
                let file = directory.appending(RelativePath(fileName))

                if !FileManager.default.fileExists(atPath: file.pathString, isDirectory: isDirectoryPointer) || isDirectoryPointer.pointee.boolValue {
                    // Files inside subdirectories will already be included in fileEnumerator.
                    // Recursively calling visit(fileOrDirectory:with:) on them here would result
                    // in duplicated counts.
                    continue
                }

                try visit(file: file, with: &reporter)
            }
        } else {
            let file = fileOrDirectory
            try visit(file: file, with: &reporter)
        }
    }

    /**
     * - Parameters:
     *   - file: Path of file to parse.
     *   - reporter: Reporter in which to store report.
     */
    private static func visit(file: AbsolutePath, with reporter: inout SwiftTypeAdoptionReporter) throws {
        guard FileManager.default.fileExists(atPath: file.pathString) else {
            throw Error.noSuchFileOrDirectory
        }

        let parsedSource = try SyntaxParser.parse(file.asURL)
        parsedSource.walk(&reporter)
    }

    /**
     * - Parameters:
     *   - sourceString: String directly containing Swift source code.
     *   - reporter: Reporter in which to store report.
     */
    private static func visit(sourceString: String, with reporter: inout SwiftTypeAdoptionReporter) throws {
        let parsedSource = try SyntaxParser.parse(source: sourceString)
        parsedSource.walk(&reporter)
    }
}

// MARK: - SyntaxVisitor
extension SwiftTypeAdoptionReporter: SyntaxVisitor {
    public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case let .identifier(identifier) where componentIdentifiers.contains(identifier):
            increment(identifier, token: token)
            return .skipChildren
        default:
            return .skipChildren
        }
    }

    public func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        switch node.base {
        case let baseIdentifierExpr as IdentifierExprSyntax:
            if case let .identifier(baseIdentifier) = baseIdentifierExpr.identifier.tokenKind {
                if componentIdentifiers.contains(baseIdentifier) {
                    increment(baseIdentifier, token: baseIdentifierExpr.identifier)
                    return .skipChildren
                }

                if let moduleName = moduleName,
                    baseIdentifier == moduleName,
                    case let .identifier(identifier) = node.name.tokenKind,
                    componentIdentifiers.contains(identifier)
                {
                    increment(identifier, token: node.name)
                    return .skipChildren
                }
            }

            return .skipChildren

        case let baseMemberAccessExpr as MemberAccessExprSyntax:
            if let moduleName = moduleName,
                let innerBaseIdentifierExpr = baseMemberAccessExpr.base as? IdentifierExprSyntax,
                case let .identifier(innerBaseIdentifier) = innerBaseIdentifierExpr.identifier.tokenKind,
                innerBaseIdentifier == moduleName,
                case let .identifier(innerIdentifier) = baseMemberAccessExpr.name.tokenKind,
                componentIdentifiers.contains(innerIdentifier)
            {
                increment(innerIdentifier, token: baseMemberAccessExpr.name)
                return .skipChildren
            }

            return .skipChildren

        default:
            return .visitChildren
        }
    }

    public func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
        if let moduleName = moduleName, let baseToken = (node.baseType as? SimpleTypeIdentifierSyntax)?.name {
            switch baseToken.tokenKind {
            case let .identifier(baseTokenIdentifier) where moduleName == baseTokenIdentifier:
                return .visitChildren
            default:
                return .skipChildren
            }
        }

        return .skipChildren
    }

    public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.identifier.tokenKind {
        case let .identifier(identifier) where componentIdentifiers.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let typeIdentifier = node.extendedType as? SimpleTypeIdentifierSyntax {
            switch typeIdentifier.name.tokenKind {
            case let .identifier(identifier) where componentIdentifiers.contains(identifier):
                if verbose {
                    print("Skipping contents of extension of \(identifier)")
                }

                return .skipChildren
            default:
                return .visitChildren
            }
        }

        return .visitChildren
    }

    public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.identifier.tokenKind {
        case let .identifier(identifier) where componentIdentifiers.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    public func visit(_ node: UnknownSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: TypeInheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: AsTypePatternSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    public func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    private func increment(_ identifier: String, token: TokenSyntax) {
        if verbose {
            print(token.verboseDescription)
        }

        usageCounts[identifier] = (usageCounts[identifier] ?? 0) + 1
    }
}

// MARK: - TokenSyntax
private extension TokenSyntax {
    var verboseDescription: String {
        // (Printing info about ancestor is typically more useful than printing the token syntax node itself.)
        let node = parent?.parent?.parent ?? self

        var output = ""
        output += node.description
        output += "\n"
        output += String(describing: type(of: node))
        output += "\n-----------------"
        return output
    }
}
