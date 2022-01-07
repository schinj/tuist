import Foundation
import TSCBasic

public enum UmbrellaHeaderHeadersExtractor {
    fileprivate enum Constants {
        static let regex = try? NSRegularExpression(pattern: "(?<=^#import (\\/|\"|<))(.+\\.h)", options: [])
        static let ignoreImports = ["UIKit", "Foundation"]
    }

    public static func headers(from path: AbsolutePath) throws -> [String] {
        let umbrellaContent = try String(contentsOf: path.url, encoding: .utf8)
        let lines = umbrellaContent.components(separatedBy: .newlines)

        return lines.compactMap { line in
            let stripped = line.trimmingCharacters(in: .whitespaces)
            guard stripped.hasPrefix("#import"),
                  let found = Constants.regex?.fistMatch(in: stripped),
                  !Constants.ignoreImports.contains(where: found.hasPrefix)
            else {
                return nil
            }
            return found.components(separatedBy: "/").last
        }
    }
}
