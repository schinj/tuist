import Foundation

extension NSRegularExpression {
    public func fistMatch(in string: String) -> String? {
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        return firstMatch(in: string, options: [], range: range).map { nsString.substring(with: $0.range) }
    }
}
