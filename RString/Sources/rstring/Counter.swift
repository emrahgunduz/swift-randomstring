import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

class Counter {
  fileprivate let queue = DispatchQueue(label: "com.markakod.Counter", attributes: .concurrent)
  fileprivate var cValue: Int

  public init (_ value: Int = 0) {
    self.cValue = value
  }

  public var value: Int {
    var result: Int = 0
    queue.sync {
      result = self.cValue
    }
    return result
  }

  public func increment (_ n: Int = 1) {
    queue.async(flags: .barrier) {
      self.cValue += n
    }
  }

  public func decrement (_ n: Int = 1) {
    queue.async(flags: .barrier) {
      self.cValue -= n
    }
  }

  static func += (left: inout Counter, right: Int) {
    left.increment(right)
  }

  static func -= (left: inout Counter, right: Int) {
    left.decrement(right)
  }
}
