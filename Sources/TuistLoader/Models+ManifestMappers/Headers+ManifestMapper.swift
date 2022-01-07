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
        let headersFromUmbrella: Set<String>?
        if let resolvedUmbrellaPath = resolvedUmbrellaPath {
            headersFromUmbrella = Set(try UmbrellaHeaderHeadersExtractor.headers(from: resolvedUmbrellaPath))
        } else {
            headersFromUmbrella = nil
        }

        var autoExlcudedPaths = Set<AbsolutePath>()
        let publicHeaders: [AbsolutePath]
        let privateHeaders: [AbsolutePath]
        let projectHeaders: [AbsolutePath]

        let allowedExtensions = TuistGraph.Headers.extensions
        func unfold(_ list: FileList?,
                    headersFromUmbrella: Set<String>? = nil) throws -> [AbsolutePath]
        {
            guard let list = list else { return [] }
            var result = try list.globs.flatMap {
                try $0.unfold(generatorPaths: generatorPaths) { path in
                    guard let fileExtension = path.extension,
                          allowedExtensions.contains(".\(fileExtension)")
                    else {
                        return false
                    }
                    guard !autoExlcudedPaths.contains(path) else {
                        return false
                    }
                    if let headersFromUmbrella = headersFromUmbrella {
                        return headersFromUmbrella.contains(path.basename)
                    } else {
                        return true
                    }
                }
            }
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
