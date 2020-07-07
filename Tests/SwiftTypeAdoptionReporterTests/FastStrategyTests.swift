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

import TSCBasic
import XCTest
@testable import SwiftTypeAdoptionReporter

final class SwiftTypeAdoptionReporterTests: XCTestCase {
    /// *Do* count calls to constructors
    func testInitVar() {
        let sourceString = "let myView = UIView()"
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count explicit type annotations on a variable
    func testInitVarWithTypeAnnotation() {
        let sourceString = "let myView: UIView = UIView()"
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count explicit type annotations on a variable
    func testDeclareVarThenSet() {
        let sourceString =
            """
            let myView: UIView
            myView = UIView()
            """
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count calls to array-type constructors
    func testInitArrayTypeVar() {
        let sourceString = "let myViews = [UIView]()"
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count explicit type annotations on an array-type variable
    func testInitArrayTypeVarWithTypeAnnotation() {
        let sourceString = "let myViews: [UIView] = [UIView]()"
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count subclasses
    func testDeclareSubclass() {
        let sourceString =
            """
            class MyView: UIView {
            }
            """
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count subclasses if includeTypeInheritance is true
    func testDeclareSubclassIncludeTypeInheritance() {
        let sourceString =
            """
            class MyView: UIView {
            }
            """
        let expected: [String: Int] = ["UIView": 1]
        verify(
            expected: expected,
            for: sourceString,
            setUp: {
                $0.includeTypeInheritance = true
            }
        )
    }

    /// *Do not* count protocol conformance
    func testProtocolConformance() {
        let sourceString =
            """
            protocol MyProtocol {}
            class Foo: UIView, MyProtocol {}
            class Bar: MyProtocol {}
            """
        let expected = ["MyProtocol": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count protocol conformance if includeTypeInheritance is true
    func testProtocolConformanceIncludeTypeInheritance() {
        let sourceString =
            """
            protocol MyProtocol {}
            class Foo: UIView, MyProtocol {}
            class Bar: MyProtocol {}
            """
        let expected = ["MyProtocol": 2]
        verify(
            expected: expected,
            for: sourceString,
            setUp: {
                $0.includeTypeInheritance = true
            }
        )
    }

    /// *Do not* count declaration of the component itself
    func testDeclareSameNameClass() {
        let sourceString =
            """
            class UIView {
            }
            """
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* include references inside the component itself
    func testReferenceInsideSameNameClassDelaraction() {
        let sourceString =
            """
            class UIView {
                let _ = UILabel()
            }
            """
        let expected: [String: Int] = ["UIView": 0, "UILabel": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* include references inside non-component class
    func testReferenceInsideOtherClass() {
        let sourceString =
            """
            class UIView {
                let _ = UILabel()
            }
            """
        let expected = [
            "UILabel": 1,
        ]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count declaraction of the component itself
    func testDeclareSameNameStruct() {
        let sourceString =
            """
            struct UIView {
            }
            """
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count declaraction of extensions on the component
    func testDeclareSameNameExtension() {
        let sourceString =
            """
            extension UIView {
            }
            """
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count function calls relative to a provided module name
    func testFunctionCallWithModuleName() {
        let sourceString = "let _ = MyModule.Foo()"
        let expected = [
            "Foo": 1,
        ]
        let moduleName = "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do not* count function calls relative to a containing module/class if no module name provided
    func testNamespacedFunctionCallWithoutModuleName() {
        let sourceString = "let _ = Foo.Bar()"
        let expected: [String: Int] = ["Bar": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count function calls relative to a containing module/class other than the provided module name
    func testNamespacedFunctionCallInNonModule() {
        let sourceString = "let _ = NotMyModule.Foo()"
        let expected: [String: Int] = ["Foo": 0]
        let moduleName =  "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do* count property references relative to a provided module name
    func testPropertyReferenceWithModuleName() {
        let sourceString = "let _ = MyModule.Foo.bar"
        let expected = [
            "Foo": 1,
        ]
        let moduleName = "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do* count property references with no module name
    func testPropertyReference() {
        let sourceString = "let _ = Foo.bar"
        let expected = [
            "Foo": 1,
        ]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count property references relative to a containing module/class if no module name provided
    func testNamespacedPropertyReferenceWithoutModuleName() {
        let sourceString = "let _ = Foo.Bar.baz"
        let expected: [String: Int] = ["Bar": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count property references relative to a containing module/class other than the provided module name
    func testNamespacedPropertyReferenceInNonModule() {
        let sourceString = "let _ = NotMyModule.Foo.bar"
        let expected: [String: Int] = ["Foo": 0]
        let moduleName =  "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do not* count property references relative to the provided module name in addition to some other module/class
    func testPropertyReferenceInModuleInNonModule() {
        let sourceString = "let _ = NotMyModule.MyModule.Foo.bar"
        let expected: [String: Int] = ["Foo": 0]
        let moduleName = "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do* count references inside another function call
    func testFunctionArgument() {
        let sourceString = "Foo(child: Foo())"
        let expected = [
            "Foo": 2,
        ]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count contents of a comment
    func testComment() {
        let sourceString = "// This is a comment about UIView"
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count contents of a string
    func testString() {
        let sourceString = "\"UIView\""
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count references in string interpolation
    func testStringInterpolation() {
        let sourceString = "\"\\(UIView())\""
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count type casting
    func testTypeCast() {
        let sourceString = "foo as UIView"
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count optional type casting
    func testOptionalTypeCasting() {
        let sourceString = "foo as? UIView"
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count force casting
    func testForceCasting() {
        let sourceString = "foo as! UIView"
        let expected: [String: Int] = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count function calls that are arguments to a chained function call
    func testFunctionCallArgumentInChainedFunctionCall() {
        let sourceString = "foo.bar(UIView()).buzz(UIView()).baz(UIView())"
        let expected = ["UIView": 3]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count property references that are arguments to a chained function call
    func testPropertyReferenceArgumentInChainedFunctionCall() {
        let sourceString = "foo.bar(UIView.someProp).buzz(UIView.someProp).baz(UIView.someProp)"
        let expected = ["UIView": 3]
        verify(expected: expected, for: sourceString)
    }

    // MARK: - Private
    private func verify(expected: [String: Int],
                        types: [String]? = nil,
                        for sourceString: String,
                        moduleName: String? = nil,
                        setUp: ((FastStrategy) -> Void)? = nil,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let types = types ?? expected.map({ key, _ in key })
        assert(!types.isEmpty, "If `expected` is an empty dictionary, a list of component identifiers to search for must be passed explicitly in the `types` argument. Otherwise the test won't really be testing anything.", file: file, line: line)

        do {
            try withTemporaryFile { tmpFile in
                tmpFile.fileHandle.write(sourceString.data(using: .utf8)!)

                let strategy = FastStrategy(
                    types: types,
                    moduleName: moduleName,
                    paths: [tmpFile.path]
                )

                setUp?(strategy)

                let actual = (try strategy.findUsageCounts()).mapValues({ $0.usageCount })
                XCTAssertEqual(expected, actual, file: file, line: line)
            }
        } catch {
            XCTFail("Failed with error \(String(describing: error))", file: file, line: line)
        }
    }
}
