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
import SwiftTypeAdoptionReporter
import TSCUtility

// MARK: - Arguments
let argumentParser = ArgumentParser(
    commandName: "swift-type-adoption-reporter",
    usage: "--types <types> --files <files> [--module <module name>] [--verbose]",
    overview: "Print how frequently each type has been used."
)

let typesArgument = argumentParser.add(
    option: "--types",
    shortName: "-t",
    kind: [String].self,
    usage: "List of types on which to report"
)

let moduleNameArgument = argumentParser.add(
    option: "--module",
    shortName: "-m",
    kind: String.self,
    usage: "Name of module containing types, to ensure types referenced by <module name>.<type name> are counted"
)

let includeTypeInheritanceArgument = argumentParser.add(
    option: "--includeTypeInheritance",
    kind: Bool.self,
    usage: "If true, include subclass and protocol conformance declarations in usage counts"
)

let formatArgument = argumentParser.add(
    option: "--format",
    shortName: "-f",
    kind: String.self,
    usage: "Output format (humanReadable|json) [default: humanReadable]"
)

let verboseArgument = argumentParser.add(
    option: "--verbose",
    shortName: "-v",
    kind: Bool.self,
    usage: "If true, print additional information about source as it is parsed"
)

// MARK: "fast" strategy arguments
let pathsArgument = argumentParser.add(
    option: "--files",
    shortName: nil,
    kind: [PathArgument].self,
    usage: "Paths in which to look for Swift source"
)

do {
    let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
    let parsedArguments = try argumentParser.parse(arguments)

    guard let types = parsedArguments.get(typesArgument) else {
        fputs("Missing types to report on.\n", stderr)
        exit(EXIT_FAILURE)
    }

    let moduleName = parsedArguments.get(moduleNameArgument)
    let includeTypeInheritance = parsedArguments.get(includeTypeInheritanceArgument) ?? false
    let verbose = parsedArguments.get(verboseArgument) ?? false

    guard let paths = parsedArguments.get(pathsArgument) else {
        fputs("Missing paths to report on.\n", stderr)
        exit(EXIT_FAILURE)
    }

    let strategy = FastStrategy(
        types: types,
        moduleName: moduleName,
        paths: paths.map({ $0.path }),
        verbose: verbose
    )
    strategy.includeTypeInheritance = includeTypeInheritance

    let formatter: ReportFormatter
    switch parsedArguments.get(formatArgument) {
    case "humanReadable", .none:
        formatter = HumanReadableReportFormatter()
    case "json":
        formatter = JSONReportFormatter()
    default:
        fputs("Invalid format specified. Valid formats are \"humanReadable\" (default), \"json\"\n", stderr)
        exit(EXIT_FAILURE)
    }

    let usageCounts = try strategy.findUsageCounts()
    let output = formatter.format(usageCounts)

    fputs("\(output)\n", stdout)
    exit(EXIT_SUCCESS)
} catch {
    fputs("\(error)\n", stderr)
    exit(EXIT_FAILURE)
}

