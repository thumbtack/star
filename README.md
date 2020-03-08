[![Build Status](https://badgen.net/travis/thumbtack/star)](https://travis-ci.com/thumbtack/star)
[![License](https://badgen.net/github/license/thumbtack/star)](https://github.com/thumbtack/star/blob/master/LICENSE)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](https://swift.org/package-manager/)

# STAR: Swift Type Adoption Reporter

Generate reports on how frequently specified Swift types are being used in your iOS codebase with a simple command-line interface.

## Install

```
$ cd star
$ make install
```

## Usage

```
$ star --components Avatar Button Color Pill --files ./

Avatar used 27 times.
Button used 167 times.
Color used 2711 times.
Pill used 9 times.
```

To report on components which are in a separate module, specify a `--moduleName`. This will ensure that  references like `Thumbprint.Button()` are captured too.

```
$ star --components Avatar Button Color Pill --files ./ --moduleName Thumbprint

Avatar used 30 times.
Button used 182 times.
Color used 2786 times.
Pill used 11 times.
```

Note: `star` is a symlink to `swift-type-adoption-reporter` for convenience. Use whichever name you prefer; they are identical.

### Options

```
USAGE: star --components <components> --files <files> [--module <module name>] [--verbose]

OPTIONS:
  --components, -c   List of components on which to report
  --files, -f        Paths in which to look for Swift source
  --module, -m       Name of module containing components, to ensure members referenced by <module name>.<component name> are counted
  --verbose, -v      If true, print additional information about source as it is parsed
  --help, -h         Display available options
```

## How it Works

STAR uses [SwiftSyntax](https://github.com/apple/swift-syntax) to traverse the AST and find references to the specified identifiers.
Since type information is not available at the AST level, usage reports may contain imperfect information when linking a reference to its identifier would require full type checking.

The reporter attempts to provide as useful information as possible, so some types of references are intentionally filtered out. For example, the line of code
```
let foo: UIView = UIView()
```
technically includes two nodes in the AST for the `UIView` identifier: one in the type annotation, and one in the constructor call. For most business uses, though, it is preferable to only count this line as a single use of `UIView`. Therefore, type annotations are ignored by STAR.

Some other examples of intentionally ignored references are code comments, class/struct/extension/etc. declarations, and inner classes within components (e.g., `MyComponent.SomeInnerClass` will match neither `MyComponent`, nor `SomeInnerClass`).

## Uninstall

```
$ cd star
$ make uninstall
```

## Contributing

If you have ideas to make STAR more useful, open an issue or submit a pull request! See below for instructions on building/testing locally.

```
$ git clone git@github.com/thumbtack/star.git
$ cd star
$ open -a Xcode .
```

### To build & run locally:
```
$ swift run swift-type-adoption-reporter ...
```

Passing in the `--verbose` argument will print out additional information which can be useful for debugging.

### To run test suite:

#### From command line:
```
$ swift test
```

#### With Xcode:
1. Create Xcode project:

    ```
    $ swift package generate-xcodeproj
    ```
2. Open `STAR.xcodeproj`
3. In Xcode, **Product -> Test**
