import Foundation
import TSCBasic
import TuistSupport

public enum UmbrellaHeaderHeadersExtractor {
    fileprivate enum Constants {
        static let regex = try? NSRegularExpression(pattern: "(?<=^#import (\\/|\"|<))(.+\\.h)", options: [])
        static let ignoreImports = ["UIKit", "Foundation"]
    }

    public static func headers(from path: AbsolutePath, for productName: String) throws -> [String] {
        let umbrellaContent = try FileHandler.shared.readTextFile(path)
        let lines = umbrellaContent.components(separatedBy: .newlines)

        return lines.compactMap { line in
            let stripped = line.trimmingCharacters(in: .whitespaces)
            let expectedPrefixes = [
                "#import \"",
                "#import <",
            ]
            guard let matchingPrefix = expectedPrefixes.first(where: { line.hasPrefix($0) }) else {
                return nil
            }
            let headerReference = stripped.dropFirst(matchingPrefix.count).dropLast()
            let headerComponents = headerReference.components(separatedBy: "/")

            // <ProductName/Header.h>
            // "ProductName/Header.h"
            let isValidProductPrefixedHeader = headerComponents.count == 2 && headerComponents[0] == productName

            // "Header.h"
            let isValidSingleHeader = headerComponents.count == 1

            guard isValidProductPrefixedHeader || isValidSingleHeader else {
                return nil
            }

            return headerComponents.last
        }
    }
}
