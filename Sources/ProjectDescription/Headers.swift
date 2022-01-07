import Foundation

/// Headers
public struct Headers: Codable, Equatable {
    /// Determine how to resolve cases
    /// when the same files are found in different header scopes
    public enum AutomaticExclusionRule: Int, Codable {
        /// Project headers = all found - private headers - public headers
        ///
        /// Order of tuist search:
        ///  1) Public headers
        ///  2) Private headers (with auto excludes all found public headers)
        ///  3) Project headers (with excluding public/private headers)
        ///
        ///  Also tuist doesn't ignore all excludes,
        ///  which had been set by `excluding` param
        case projectExcludesPrivateAndPublic

        /// Public headers = all found - private headers - project headers
        ///
        /// Order of tuist search (reverse search):
        ///  1) Project headers
        ///  2) Private headers (with auto excludes all found project headers)
        ///  3) Public headers (with excluding project/private headers)
        ///
        ///  Also tuist doesn't ignore all excludes,
        ///  which had been set by `excluding` param
        case publicExcludesPrivateAndProject
    }

    /// Umbrella header path, which wil be parsed
    /// to get list of public headers
    public let umbrellaHeader: Path?

    /// Relative path to public headers.
    public let `public`: FileList?

    /// Relative path to private headers.
    public let `private`: FileList?

    /// Relative path to project headers.
    public let project: FileList?

    /// Determine how to resolve cases
    /// when the same files are found in different header scopes
    public let exclusionRule: AutomaticExclusionRule

    private init(public: FileList? = nil,
                 umbrellaHeader: Path? = nil,
                 private: FileList? = nil,
                 project: FileList? = nil,
                 exclusionRule: AutomaticExclusionRule)
    {
        self.public = `public`
        self.umbrellaHeader = umbrellaHeader
        self.private = `private`
        self.project = project
        self.exclusionRule = exclusionRule
    }

    /// - deprecated: use `headers(public:private:project:exclusionRule:)` to create Headers instance.
    @available(
        *,
        deprecated,
        message: "Use `headers(public:private:project:exclusionRule:)` to create Headers instance."
    )
    public init(public: FileList? = nil,
                private: FileList? = nil,
                project: FileList? = nil)
    {
        self = .init(
            public: `public`,
            private: `private`,
            project: project,
            exclusionRule: .projectExcludesPrivateAndPublic
        )
    }

    public static func headers(public: FileList? = nil,
                               private: FileList? = nil,
                               project: FileList? = nil,
                               exclusionRule: AutomaticExclusionRule = .projectExcludesPrivateAndPublic) -> Headers
    {
        .init(
            public: `public`,
            private: `private`,
            project: project,
            exclusionRule: exclusionRule
        )
    }

    private static func headers(from list: FileList,
                               umbrella: Path,
                               private: FileList? = nil,
                               allOthersAsProject: Bool) -> Headers
    {
        return .init(
            public: list,
            umbrellaHeader: umbrella,
            private: `private`,
            project: allOthersAsProject ? list : nil,
            exclusionRule: .projectExcludesPrivateAndPublic
        )
    }

    /// Loading headers from the file list,
    /// as `public` will be marked all presented in the umbrella header
    /// as `private` - all from the file list of private headers (exclude already found `public`)
    /// as `project` - all others
    /// - Parameters:
    ///     - from: File list, which contains `public` and `project` headers
    ///     - umbrella: File path to the umbrella header
    ///     - private: File list, which contains `private` headers
    public static func allHeaders(from list: FileList,
                                  umbrella: Path,
                                  private: FileList? = nil) -> Headers
    {
        return headers(
            from: list,
            umbrella: umbrella,
            private: `private`,
            allOthersAsProject: true
        )
    }

    /// Loading headers from the file list,
    /// as `public` will be marked all presented in the umbrella header
    /// as `private` - all from the file list of private headers (exclude already found `public`)
    /// `project` will be empty - all other headers will be skipped
    /// - Parameters:
    ///     - from: File list, which contains `public` and `project` headers
    ///     - umbrella: File path to the umbrella header
    ///     - private: File list, which contains `private` headers
    public static func onlyHeaders(from list: FileList,
                                   umbrella: Path,
                                   private: FileList? = nil) -> Headers
    {
        return headers(
            from: list,
            umbrella: umbrella,
            private: `private`,
            allOthersAsProject: false
        )
    }
}
