import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

infix operator **: MultiplicationPrecedence

public extension Int {
  static func ** (left: Int, right: Int) -> Int {
    return Int(pow(CGFloat(left), CGFloat(right)))
  }
}