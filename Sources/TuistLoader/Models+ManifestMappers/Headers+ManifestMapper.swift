import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport

extension TuistGraph.Headers {
    /// Maps a ProjectDescription.Headers instance into a TuistGraph.Headers model.
    /// Glob patterns are resolved as part of the mapping process.
    /// - Parameters:
    ///   - manifest: Manifest representation of Headers.
    ///   - generatorPaths: Generator paths.
    static func from(manifest: ProjectDescription.Headers, generatorPaths: GeneratorPaths) throws -> TuistGraph.Headers {
        let resolvedUmbrellaPath = try manifest.umbrellaHeader.map { try generatorPaths.resolve(path: $0) }
        let headersFromUmbrella = try manifest.publicHeadersFromUmbrella(resolvedPath: resolvedUmbrellaPath)

        var autoExlcudedPaths = Set<AbsolutePath>()
        let publicHeaders: [AbsolutePath]
        let privateHeaders: [AbsolutePath]
        let projectHeaders: [AbsolutePath]

        func unfold(_ list: FileList?, headersFromUmbrella: Set<String>? = nil) throws -> [AbsolutePath] {
            guard let list = list else { return [] }
            var result = try list.unfold(
                generatorPaths: generatorPaths,
                basenameFilter: headersFromUmbrella,
                additionalExcluding: autoExlcudedPaths
            )
            // be sure, that umbrella already here (if we use it)
            if headersFromUmbrella != nil,
               let resolvedUmbrellaPath = resolvedUmbrellaPath,
               !result.contains(resolvedUmbrellaPath)
            {
                result.append(resolvedUmbrellaPath)
            }
            return result
        }

        switch manifest.exclusionRule {
        case .projectExcludesPrivateAndPublic:
            publicHeaders = try unfold(manifest.public, headersFromUmbrella: headersFromUmbrella)
            autoExlcudedPaths.formUnion(publicHeaders)
            privateHeaders = try unfold(manifest.private)
            autoExlcudedPaths.formUnion(privateHeaders)
            projectHeaders = try unfold(manifest.project)

        case .publicExcludesPrivateAndProject:
            projectHeaders = try unfold(manifest.project)
            autoExlcudedPaths.formUnion(projectHeaders)
            privateHeaders = try unfold(manifest.private)
            autoExlcudedPaths.formUnion(privateHeaders)
            publicHeaders = try unfold(manifest.public, headersFromUmbrella: headersFromUmbrella)
        }

        return Headers(public: publicHeaders, private: privateHeaders, project: projectHeaders)
    }
}

extension FileList {
    fileprivate func unfold(
        generatorPaths: GeneratorPaths,
        basenameFilter: Set<String>? = nil,
        additionalExcluding: Set<AbsolutePath>
    ) throws -> [AbsolutePath] {
        return try globs.flatMap {
            try $0.unfold(
                generatorPaths: generatorPaths,
                basenameFilter: basenameFilter,
                additionalExcluding: additionalExcluding
            )
        }
    }
}

extension FileListGlob {
    fileprivate func unfold(
        generatorPaths: GeneratorPaths,
        basenameFilter: Set<String>?,
        additionalExcluding: Set<AbsolutePath>
    ) throws -> [AbsolutePath] {
        let resolvedPath = try generatorPaths.resolve(path: glob)
        let resolvedExcluding = (try resolvedExcluding(generatorPaths: generatorPaths)).union(additionalExcluding)
        return resolvedPath.unfold(basenameFilter: basenameFilter, excluding: resolvedExcluding)
    }

    fileprivate func resolvedExcluding(generatorPaths: GeneratorPaths) throws -> Set<AbsolutePath> {
        guard !excluding.isEmpty else { return [] }
        var result: Set<AbsolutePath> = []
        try excluding.forEach { path in
            let resolved = try generatorPaths.resolve(path: path).pathString
            let absolute = AbsolutePath(resolved)
            let globs = AbsolutePath(absolute.dirname).glob(absolute.basename)
            result.formUnion(globs)
        }
        return result
    }
}

extension AbsolutePath {
    fileprivate func unfold(basenameFilter: Set<String>?, excluding: Set<AbsolutePath>) -> [AbsolutePath] {
        FileHandler.shared.glob(AbsolutePath.root, glob: String(pathString.dropFirst())).filter {
            guard let fileExtension = $0.extension else {
                return false
            }
            guard TuistGraph.Headers.extensions.contains(".\(fileExtension)"),
                  !excluding.contains($0)
            else {
                return false
            }
            if let basenameFilter = basenameFilter {
                return basenameFilter.contains($0.basename)
            } else {
                return true
            }
        }
    }
}

extension ProjectDescription.Headers {
    fileprivate enum Constants {
        static let regex = try? NSRegularExpression(pattern: "(?<=^#import (\\/|\"|<))(.+\\.h)", options: [])
        static let ignoreImports = ["UIKit", "Foundation"]
    }

    fileprivate func publicHeadersFromUmbrella(resolvedPath: AbsolutePath?) throws -> Set<String>? {
        guard let resolvedPath = resolvedPath else {
            return nil
        }
        let umbrellaContent = try String(contentsOf: resolvedPath.url, encoding: .utf8)
        let lines = umbrellaContent.components(separatedBy: .newlines)

        let foundHeaders: [String] = lines.compactMap { line in
            let stripped = line.trimmingCharacters(in: .whitespaces)
            guard stripped.hasPrefix("#import"),
                  let found = Constants.regex?.fistMatch(in: stripped),
                  !Constants.ignoreImports.contains(where: found.hasPrefix)
            else {
                return nil
            }
            return found.components(separatedBy: "/").last
        }
        return Set(foundHeaders)
    }
}

extension NSRegularExpression {
    fileprivate func fistMatch(in string: String) -> String? {
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        return firstMatch(in: string, options: [], range: range).map { nsString.substring(with: $0.range) }
    }
}
