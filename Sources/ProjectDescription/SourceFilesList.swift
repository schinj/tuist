// MARK: - FileList

/// A model to refer to source files that supports passing compiler flags.
public struct SourceFileGlob: Codable, Equatable {
    /// Relative glob pattern.
    public let glob: Path

    /// Relative glob patterns for excluded files.
    public let excluding: [Path]

    /// Compiler flags.
    public let compilerFlags: String?

    /// Source file code generation attribute
    public let codeGen: FileCodeGen?

    /// Initializes a SourceFileGlob instance.
    ///
    /// - Parameters:
    ///   - glob: Relative glob pattern.
    ///   - excluding: Relative glob patterns for excluded files.
    ///   - compilerFlags: Compiler flags.
    ///   - codegen: Source file code generation attribute
    public static func glob(
        _ glob: Path,
        excluding: [Path] = [],
        compilerFlags: String? = nil,
        codeGen: FileCodeGen? = nil
    ) -> Self {
        .init(glob: glob, excluding: excluding, compilerFlags: compilerFlags, codeGen: codeGen)
    }

    public static func glob(
        _ glob: Path,
        excluding: Path?,
        compilerFlags: String? = nil,
        codeGen: FileCodeGen? = nil
    ) -> Self {
        let paths: [Path] = excluding.flatMap { [$0] } ?? []
        return .init(glob: glob, excluding: paths, compilerFlags: compilerFlags, codeGen: codeGen)
    }
}

extension SourceFileGlob: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(glob: Path(value), excluding: [], compilerFlags: nil, codeGen: nil)
    }
}

public struct SourceFilesList: Codable, Equatable {
    /// List glob patterns.
    public let globs: [SourceFileGlob]

    /// Initializes the source files list with the glob patterns.
    ///
    /// - Parameter globs: Glob patterns.
    public init(globs: [SourceFileGlob]) {
        self.globs = globs
    }

    /// Initializes the source files list with the glob patterns as strings.
    ///
    /// - Parameter globs: Glob patterns.
    public init(globs: [String]) {
        self.globs = globs.map(SourceFileGlob.init)
    }

    /// Initializes a sources list with a list of paths.
    /// - Parameter paths: Source paths.
    public static func paths(_ paths: [Path]) -> SourceFilesList {
        SourceFilesList(globs: paths.map { .glob($0) })
    }
}

/// Support file as single string
extension SourceFilesList: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(globs: [value])
    }
}

extension SourceFilesList: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: SourceFileGlob...) {
        self.init(globs: elements)
    }
}
