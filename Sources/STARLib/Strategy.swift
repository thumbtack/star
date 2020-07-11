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

public struct TypeUsage {
    /// Number of files this type was used in
    let fileCount: Int

    /// Number of times this type was used
    let usageCount: Int
}

public protocol Strategy: AnyObject {
    /// A Boolean value indicating whether the strategy should include subclass declaration
    /// and protocol conformance in usage counts.
    var includeTypeInheritance: Bool { get set }

    func findUsageCounts() throws -> [String: TypeUsage]
}
