import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public extension String {

  public var lines: [String] {
    return self.components(separatedBy: "\n")
  }

  public func trim () -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespaces)
  }

  public static func randomString (length: Int, allowed: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
    let allowedCharsCount = UInt32(allowed.count)
    var randomString      = ""

    for _ in 0 ..< length {
      let randomNum    = Int(arc4random_uniform(allowedCharsCount))
      let randomIndex  = allowed.index(allowed.startIndex, offsetBy: randomNum)
      let newCharacter = allowed[randomIndex]
      randomString += String(newCharacter)
    }

    return randomString
  }

  public var uniqueCharacters: String {
    var characterCounts = [Character: Int]()
    self.forEach { char in
      if characterCounts[char] != nil {
        characterCounts[char]! += 1
      } else {
        characterCounts[char] = 1
      }
    }

    let uniqueList = self.filter { characterCounts[$0]! == 1 }
    return uniqueList.map { String($0) }.joined()
  }

}