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
import SPMUtility

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

let filesArgument = argumentParser.add(
    option: "--files",
    shortName: "-f",
    kind: [PathArgument].self,
    usage: "Paths in which to look for Swift source"
)

let moduleNameArgument = argumentParser.add(
    option: "--module",
    shortName: "-m",
    kind: String.self,
    usage: "Name of module containing types, to ensure types referenced by <module name>.<type name> are counted"
)

let verboseArgument = argumentParser.add(
    option: "--verbose",
    shortName: "-v",
    kind: Bool.self,
    usage: "If true, print additional information about source as it is parsed"
)

let stdout = FileHandle.standardOutput
let stderr = FileHandle.standardError

do {
    let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
    let parsedArguments = try argumentParser.parse(arguments)

    let output = try SwiftTypeAdoptionReporter.report(
        parsedArguments.get(typesArgument)!,
        for: parsedArguments.get(filesArgument)!.map({ $0.path }),
        moduleName: parsedArguments.get(moduleNameArgument),
        verbose: parsedArguments.get(verboseArgument) ?? false
    )

    stdout.write("\(output)\n".data(using: .utf8)!)
} catch let error as ArgumentParserError {
    stderr.write("\(error.description)\n".data(using: .utf8)!)
} catch SwiftTypeAdoptionReporter.Error.noSuchFileOrDirectory {
    stderr.write("The specified file/direcotry could not be found.".data(using: .utf8)!)
} catch {
    stderr.write("\(error.localizedDescription)\n".data(using: .utf8)!)
}

