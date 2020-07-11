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

import Foundation
import SwiftSyntax
import TSCBasic

public class FastStrategy: SyntaxVisitor, Strategy {
    public var includeTypeInheritance: Bool = false

    public init(types: [String],
                moduleName: String?,
                paths: [AbsolutePath],
                verbose: Bool = false) {
        self.types = types
        self.moduleName = moduleName
        self.paths = paths
        self.verbose = verbose
    }

    public func findUsageCounts() throws -> [String: TypeUsage] {
        fileCounts = [:]
        usageCounts = [:]

        for path in paths {
            try visit(fileOrDirectory: path)
        }

        var typeUsages: [String: TypeUsage] = [:]
        for type in types {
            typeUsages[type] = TypeUsage(
                fileCount: fileCounts[type]?.count ?? 0,
                usageCount: usageCounts[type] ?? 0
            )
        }

        if verbose {
            for type in types {
                guard let files = fileCounts[type] else { continue }

                print("\(type) used in the following files:")
                files
                    .map({ " \($0.pathString)" })
                    .forEach { print($0) }
            }
        }

        return typeUsages
    }

    enum Error: Swift.Error, CustomStringConvertible {
        case noSuchFileOrDirectory(URL)

        var description: String {
            switch self {
            case let .noSuchFileOrDirectory(url):
                return "No such file or directory: \(url.path)"
            }
        }
    }

    // MARK: - SyntaxVisitor
    override public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            increment(identifier, token: token)
            return .skipChildren
        default:
            return .skipChildren
        }
    }

    override public func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard let base = node.base else { return .visitChildren }

        if let baseIdentifierExpr = base.as(IdentifierExprSyntax.self) {
            if case let .identifier(baseIdentifier) = baseIdentifierExpr.identifier.tokenKind {
                if types.contains(baseIdentifier) {
                    increment(baseIdentifier, token: baseIdentifierExpr.identifier)
                    return .skipChildren
                }

                if let moduleName = moduleName,
                    baseIdentifier == moduleName,
                    case let .identifier(identifier) = node.name.tokenKind,
                    types.contains(identifier) {
                    increment(identifier, token: node.name)
                    return .skipChildren
                }
            }

            return .skipChildren

        } else if let baseMemberAccessExpr = base.as(MemberAccessExprSyntax.self) {
            if let moduleName = moduleName,
                let innerBaseIdentifierExpr = baseMemberAccessExpr.base?.as(IdentifierExprSyntax.self),
                case let .identifier(innerBaseIdentifier) = innerBaseIdentifierExpr.identifier.tokenKind,
                innerBaseIdentifier == moduleName,
                case let .identifier(innerIdentifier) = baseMemberAccessExpr.name.tokenKind,
                types.contains(innerIdentifier) {
                increment(innerIdentifier, token: baseMemberAccessExpr.name)
                return .skipChildren
            }

            return .skipChildren
        }

        return .visitChildren
    }

    override public func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
        if let moduleName = moduleName, let baseToken = node.baseType.as(SimpleTypeIdentifierSyntax.self)?.name {
            switch baseToken.tokenKind {
            case let .identifier(baseTokenIdentifier) where moduleName == baseTokenIdentifier:
                return .visitChildren
            default:
                return .skipChildren
            }
        }

        return .skipChildren
    }

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.identifier.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    override public func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.identifier.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    override public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let typeIdentifier = node.extendedType.as(SimpleTypeIdentifierSyntax.self) {
            switch typeIdentifier.name.tokenKind {
            case let .identifier(identifier) where types.contains(identifier):
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

    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.identifier.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    override public func visit(_ node: UnknownSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: TypeInheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        if includeTypeInheritance {
            for inheritedType in node.inheritedTypeCollection {
                guard let typeIdentifier = inheritedType.typeName.as(SimpleTypeIdentifierSyntax.self) else { continue }

                switch typeIdentifier.name.tokenKind {
                case let .identifier(identifier) where types.contains(identifier):
                    increment(identifier, token: typeIdentifier.name)

                default:
                    break
                }
            }

            return .skipChildren
        } else {
            return .skipChildren
        }
    }

    override public func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: AsTypePatternSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override public func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    // MARK: - Private
    private let types: [String]
    private let moduleName: String?
    private let paths: [AbsolutePath]
    private let verbose: Bool
    private var fileCounts: [String: Set<AbsolutePath>] = [:]
    private var usageCounts: [String: Int] = [:]
    private var currentFile: AbsolutePath?

    /**
     * - Parameters:
     *   - fileOrDirectory: Path of file/directory to parse.
     *   - reporter: Reporter in which to store report.
     */
    private func visit(fileOrDirectory: AbsolutePath) throws {
        let isDirectoryPointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        guard FileManager.default.fileExists(atPath: fileOrDirectory.pathString, isDirectory: isDirectoryPointer) else {
            throw Error.noSuchFileOrDirectory(fileOrDirectory.asURL)
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

                try visit(file: file)
            }
        } else {
            let file = fileOrDirectory
            try visit(file: file)
        }
    }

    /**
     * - Parameters:
     *   - file: Path of file to parse.
     *   - reporter: Reporter in which to store report.
     */
    private func visit(file: AbsolutePath) throws {
        guard FileManager.default.fileExists(atPath: file.pathString) else {
            throw Error.noSuchFileOrDirectory(file.asURL)
        }

        currentFile = file

        let parsedSource = try SyntaxParser.parse(file.asURL)
        walk(parsedSource)
    }

    private func increment(_ identifier: String, token: TokenSyntax) {
        if verbose {
            print(token.verboseDescription)
        }

        usageCounts[identifier] = (usageCounts[identifier] ?? 0) + 1

        if let currentFile = currentFile {
            if fileCounts[identifier] != nil {
                fileCounts[identifier]?.insert(currentFile)
            } else {
                fileCounts[identifier] = [currentFile]
            }
        }
    }
}

// MARK: - TokenSyntax
private extension TokenSyntax {
    var verboseDescription: String {
        // (Printing info about ancestor is typically more useful than printing the token syntax node itself.)
        let node: CustomStringConvertible = parent?.parent?.parent ?? self

        var output = ""
        output += node.description
        output += "\n"
        output += String(describing: type(of: node))
        output += "\n-----------------"
        return output
    }
}
