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
import SwiftSyntax

public class FastStrategy: Strategy {
    public init(types: [String],
         moduleName: String?,
         paths: [AbsolutePath],
         verbose: Bool = false) {
        self.types = types
        self.moduleName = moduleName
        self.paths = paths
        self.verbose = verbose
    }

    public func findUsageCounts() throws -> [String : Int] {
        usageCounts  = [:]

        for path in paths {
            try visit(fileOrDirectory: path)
        }

        return usageCounts
    }

    enum Error: Swift.Error {
        case noSuchFileOrDirectory
    }

    // MARK: - Private
    private let types: [String]
    private let moduleName: String?
    private let paths: [AbsolutePath]
    private let verbose: Bool
    private var usageCounts: [String: Int] = [:]

    /**
    * - Parameters:
    *   - fileOrDirectory: Path of file/directory to parse.
    *   - reporter: Reporter in which to store report.
    */
    private func visit(fileOrDirectory: AbsolutePath) throws {
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
            throw Error.noSuchFileOrDirectory
        }

        let parsedSource = try SyntaxParser.parse(file.asURL)
        var visitor = self
        parsedSource.walk(&visitor)
    }

    /**
     * - Parameters:
     *   - sourceString: String directly containing Swift source code.
     *   - reporter: Reporter in which to store report.
     */
    private func visit(sourceString: String) throws {
        let parsedSource = try SyntaxParser.parse(source: sourceString)
        var visitor = self
        parsedSource.walk(&visitor)
    }
}

// MARK: - SyntaxVisitor
extension FastStrategy: SyntaxVisitor {
    public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
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
                if types.contains(baseIdentifier) {
                    increment(baseIdentifier, token: baseIdentifierExpr.identifier)
                    return .skipChildren
                }

                if let moduleName = moduleName,
                    baseIdentifier == moduleName,
                    case let .identifier(identifier) = node.name.tokenKind,
                    types.contains(identifier)
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
                types.contains(innerIdentifier)
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
        case let .identifier(identifier) where types.contains(identifier):
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

    public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
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

        let key: String
        if let moduleName = moduleName {
            key = "\(moduleName).\(identifier)"
        } else {
            key = identifier
        }

        usageCounts[key] = (usageCounts[key] ?? 0) + 1
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
