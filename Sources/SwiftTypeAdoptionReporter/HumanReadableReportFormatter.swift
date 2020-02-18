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

public class HumanReadableReportFormatter: ReportFormatter {
    public init() {
    }

    public func format(_ usageCounts: [String: TypeUsage]) -> String {
        let sortedUsageCounts = usageCounts.sorted(by: { $0.key < $1.key })

        var output = ""
        for (componentName, typeUsage) in sortedUsageCounts {
            let fileCount = typeUsage.fileCount
            let usageCount = typeUsage.usageCount
            output += "\(componentName) used \(usageCount) time\(usageCount != 1 ? "s" : "") in \(fileCount) file\(fileCount != 1 ? "s" : "").\n"
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
