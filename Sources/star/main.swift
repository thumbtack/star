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

import ArgumentParser
import Foundation
import STARLib

struct MainCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "star",
        abstract: "Print how frequently each type has been used."
    )

    @Option(
        name: .shortAndLong,
        parsing: .upToNextOption,
        help: "List of types on which to report"
    )
    var types: [String] = []

    @Option(
        name: [.customLong("module"), .short],
        help: "Name of module containing types, to ensure types referenced by <module name>.<type name> are counted"
    )
    var moduleName: String?

    @Option(
        name: .shortAndLong,
        help: "Output format (humanReadable|json)"
    )
    var format: OutputFormat = .humanReadable

    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Paths in which to look for Swift source"
    )
    var files: [URL] = []

    @Flag(
        name: .customLong("includeTypeInheritance"),
        help: "Include subclass and protocol conformance declarations in usage counts"
    )
    var includeTypeInheritance: Bool = false

    @Flag(
        name: .shortAndLong,
        help: "Print additional information about source as it is parsed"
    )
    var verbose: Bool = false

    func run() throws {
        guard !types.isEmpty else {
            throw MainCommandError.missingTypesArgument
        }

        guard !files.isEmpty else {
            throw MainCommandError.missingFilesArgument
        }

        let strategy = FastStrategy(
            types: types,
            moduleName: moduleName,
            paths: files,
            verbose: verbose
        )
        strategy.includeTypeInheritance = includeTypeInheritance

        let formatter = format.makeFormatter()

        let usageCounts = try strategy.findUsageCounts()
        let output = formatter.format(usageCounts)

        print(output)
    }
}

enum MainCommandError: Error, CustomStringConvertible {
    case missingTypesArgument
    case missingFilesArgument

    var description: String {
        switch self {
        case .missingTypesArgument:
            return "Missing types to report on."
        case .missingFilesArgument:
            return "Missing files to report on."
        }
    }
}

MainCommand.main()
