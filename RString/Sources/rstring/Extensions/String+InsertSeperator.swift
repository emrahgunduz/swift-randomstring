import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public extension String {

  private var pairs: [String] {
    var result: [String] = []
    let characters       = Array(self)
    stride(from: 0, to: count, by: 2).forEach {
      result.append(String(characters[$0 ..< min($0 + 2, count)]))
    }
    return result
  }

  private func inserting (separator: String, every n: Int) -> String {
    var result: String = ""
    let characters     = Array(self)
    stride(from: 0, to: count, by: n).forEach {
      result += String(characters[$0 ..< min($0 + n, count)])
      if $0 + n < count {
        result += separator
      }
    }
    return result
  }

  mutating func insert (separator: String, every n: Int, fromEnd: Bool = false) {
    if (fromEnd) {
      self = String(self.reversed())
    }

    self = inserting(separator: separator, every: n)

    if (fromEnd) {
      self = String(self.reversed())
    }
  }

}